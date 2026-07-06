# showfase — 設計ドキュメント

Flutter の `@Preview`(`package:flutter/widget_previews.dart`)を収集し、実機・シミュレータ・Web で動く UI カタログアプリを生成する、Showkase の Flutter 版。

- ステータス: **提案(承認待ち)**
- 作成日: 2026-07-06
- 調査ソース: Flutter 3.41.6 ローカル SDK 実物(`widget_previews.dart`, `flutter_tools/src/widget_preview/*`)、flutter/flutter GitHub(タグ 3.35.0 / 3.38.0 / 3.41.0 / 3.44.0 / master)、airbnb/Showkase master、pub.dev / dart-lang/build / widgetbook / injectable / auto_route 各リポジトリ

---

## 1. 調査結果サマリ

### 1.1 `widget_previews` API(確定事項)

Flutter 3.38.0〜3.44.0(現 stable)で API は同一。**ベースラインは Flutter 3.38+** とする。

```dart
// package:flutter/widget_previews.dart(3.38–3.44 で同一)
typedef PreviewTheme = PreviewThemeData Function();
typedef WidgetWrapper = Widget Function(Widget);
typedef PreviewLocalizations = PreviewLocalizationsData Function();

base class Preview {
  const Preview({
    String group = 'Default',
    String? name,
    Size? size,
    double? textScaleFactor,
    WidgetWrapper? wrapper,
    PreviewTheme? theme,
    Brightness? brightness,
    PreviewLocalizations? localizations,
  });
  @mustCallSuper
  Preview transform() => this;  // 実行時変換フック(サブクラスがオーバーライド可)
}

abstract base class MultiPreview {
  const MultiPreview();
  List<Preview> get previews;   // Preview とは別階層。サブクラス化して使う
  @mustCallSuper
  List<Preview> transform() => previews.map((e) => e.transform()).toList();
}
```

- 対象: トップレベル関数 / クラスの static メソッド / 必須引数のない public コンストラクタ・ファクトリ。戻り値は `Widget` または `WidgetBuilder`、public であること
- アノテーション引数はすべて const。`wrapper`/`theme`/`localizations` は public な static 関数(トップレベルまたは static メンバ)への参照(tear-off)であること
- `Preview` は `base class` なのでユーザーがサブクラス化したカスタムアノテーションを作れる。検出は「`Preview` または `MultiPreview` のサブタイプか」で判定する必要がある
- 3.35 には `group` / `MultiPreview` / `transform()` が**存在しない**(3.38 で追加)。3.35 サポートは切る
- **注意(破壊的変更が確定)**: master(PR #188176、2026-06-30 マージ)で `PreviewThemeData` が abstract 化され `Widget apply(BuildContext, Widget)` を持つ形に変わる(`MaterialPreviewThemeData` 等へ分離)。次の stable で入る。→ §8 リスク参照
- API 全体に「this interface is not stable and **will change**」の明記あり(実験的 API)

### 1.2 flutter_tools 自身の実装(最重要の先行実装)

`flutter_tools` の Widget Previewer は build_runner ではなく analyzer 直接駆動だが、**検出とコード生成の戦略はそのまま流用できる**:

- **検出**: AST visitor で、アノテーションのコンストラクタの型が `package:flutter/src/widget_previews/widget_previews.dart` の `Preview`/`MultiPreview` のサブタイプかを `allSupertypes` で判定。要素側は「必須引数なし」「戻り値型トークンが `Widget`/`WidgetBuilder`」「public」をチェック
- **記録**: `scriptUri` / `line` / `column` / `packageName` / `functionName`(`MyWidget.preview` 形式)/ `isBuilder` / `isMultiPreview` / アノテーション定数の `DartObject` そのもの
- **生成(核心)**: アノテーションの `DartObject` を静的に分解してメタデータ化するのではなく、**const 式として生成コードに再構築して埋め込み**(`code_builder` の scoped allocator でプレフィックス付き import、enum・ネスト const・関数 tear-off まで再帰的に復元)、**実行時に `.transform()` を呼ぶ**。MultiPreview は実行時に `preview.transform().map(...)` でスプレッド展開
- ランタイム側は `WidgetPreview(builder, previewData: Preview, scriptUri, line, column, packageName)` + `buildWidgetPreview` / `buildMultiWidgetPreview` ヘルパー。`WidgetBuilder` 戻りは `Builder(builder: fn())` でラップ

この「**const 式の再出力 + 実行時 transform()**」方式なら、カスタム `Preview` サブクラス・`MultiPreview` 派生・`transform()` オーバーライド・tear-off をすべて型情報を失わず完全に扱える。showfase もこれを踏襲する。

### 1.3 Showkase のアーキテクチャ(移植元)

- 3 層構造: annotation(依存なし)→ processor(モジュールごとに中間メタデータ + 実体プロパティを生成、`@ShowkaseRoot` のあるモジュールで classpath を走査して集約 `Codegen` クラスを生成)→ browser UI(グループ一覧 → グループ内コンポーネント → 詳細画面)
- メタデータモデルは `ShowkaseBrowserComponent(group, componentName, componentKDoc, component: @Composable () -> Unit, widthDp, heightDp, ...)` — **コンポーネントをゼロ引数クロージャで保持**し、詳細画面では同じクロージャを環境オーバーライド(フォントスケール×2、表示スケール×2、RTL、ダークモード)で 5 回描画する
- Compose の `@Preview` と独自 `@ShowkaseComposable` を同じモデルに正規化し、両方付いている場合は複合キーで dedupe
- **真似る**: クロージャ保持モデル / 環境オーバーライドによるパーミュテーション / エコシステム標準の `@Preview` への便乗 / 単一カテゴリ時に一覧画面をスキップする navigation / 検索状態の保持
- **避ける**: `Class.forName` によるリフレクション連結(Dart AOT では不可能、生成 import で直結する方が堅牢)/ 実行時エラーでしか分からない root 未設定(ビルド時エラーにできる)/ KAPT/KSP 二重実装の複雑さ

### 1.4 build_runner / source_gen エコシステム(2026-07 時点)

- 現行 stable: `analyzer` 14.0.0 / `build` 4.0.6 / `build_runner` 2.15.0 / `source_gen` 4.2.3 / `build_test` 3.5.15 / `source_gen_test` 1.3.6 / `code_builder` 4.11.1 / `dart_style` 3.1.9。`source_gen` 4.x は analyzer `>=8.1.1 <14.0.0`
- `TypeChecker.fromRuntime` は source_gen 4.0 で**削除済み**。Flutter 所有のアノテーションには `TypeChecker.typeNamedLiterally('Preview', inPackage: 'flutter')` を使う(export 経路や `src/` 移動に強い)。サブクラスを拾うため assignable 判定(`annotationsOf`)を使う
- **集約ビルダーの標準形は 2 フェーズ**: widgetbook_generator / injectable_generator / auto_route_generator がすべて同型 — ① per-library スキャナが `.dart → .xxx.json`(`build_to: cache`, `runs_before`)、② 集約ジェネレータがユーザーのアンカーアノテーション(widgetbook の `@App` 等)を持つファイルに `GeneratorForAnnotation` で反応し、`buildStep.findAssets(Glob('**.xxx.json'))` で読み集めて 1 ファイル出力(`build_to: source`)
- **ビルダーパッケージは flutter に依存してはならない**(build script は pure Dart VM で動き `dart:ui` 到達で死ぬ: flutter/flutter#132125)。ただし resolver 経由でユーザープロジェクト内の flutter コードを解析するのは自由(widgetbook が実証)。生成**先**ファイルは flutter を自由に import できる
- 関数型フィールドは `DartObject.toFunctionValue()` → `ExecutableElement` から名前と library URI を取り、tear-off として再出力
- テスト: 集約ビルダーは `build_test` の `testBuilders`(fake flutter スタブをアセットに入れる)、抽出・出力は pure function 化して `equalsDart` でゴールデンテスト。`source_gen_test` は per-element 用

---

## 2. 全体アーキテクチャ

pub workspace(Dart 3.6+)+ melos によるモノレポ。

```
showfase/                        # ルート: pub workspace + melos
├── pubspec.yaml                 # workspace: [packages/*, packages/showfase/example]
├── DESIGN.md / README.md / LICENSE (Apache-2.0)
└── packages/
    ├── showfase_annotation/     # pure Dart。@ShowfaseRoot のみ(最小)
    ├── showfase_generator/      # pure Dart。build_runner ビルダー(2フェーズ)
    └── showfase/                # Flutter ランタイム。モデル + ShowfaseBrowser UI
        └── example/             # デモアプリ(生成ファイルコミット済み、pub.dev 慣行位置)
```

依存関係:

```
example ──────────┬─> showfase ─> flutter (>=3.38)
                  ├─> showfase_annotation (pure Dart, deps: meta のみ)
                  └─(dev)─> showfase_generator ─> analyzer/build/source_gen/code_builder/dart_style
                                                  (flutter 非依存!)
showfase ─> showfase_annotation
```

データフロー(Showkase の 3 層の写像):

```
① ユーザーコード: @Preview / @MultiPreview派生 付き関数
        │  dart run build_runner build
② showfase_generator:
   [phase 1] preview_scanner: 各ライブラリを走査 → .showfase.json (cache)
   [phase 2] showfase_builder: @ShowfaseRoot のファイルに反応、
             全 .showfase.json を集約 → showfase.g.dart (source, コミット対象)
        │
③ showfase ランタイム: showfasePreviews() が返す List<ShowfasePreview> を
   ShowfaseApp / ShowfaseBrowser に渡してカタログ表示
```

## 3. `showfase_annotation`

pure Dart(deps: `meta` のみ)。**独自アノテーションは最小限**とし、`@Preview` を第一級で読む方針。

```dart
/// カタログの集約点。カタログアプリのエントリポイント(main 関数や App クラス)
/// など、実在するトップレベル宣言に付与する。showfase_builder はこの宣言を
/// 含むファイルの隣に showfase.g.dart を生成する。
@Target({TargetKind.function, TargetKind.classType})
class ShowfaseRoot {
  const ShowfaseRoot();
}
```

v1 ではこれのみ。`@ShowfaseSkip`(特定 preview の除外)は要望が出たら追加(builder options の `exclude` glob で大半は代替可能)。

ユーザーの使い方 — auto_route(`@AutoRouterConfig` を実際に使うルータークラスに付与)や widgetbook(`@App` をカタログアプリの Widget に付与し、そのファイルが `main.directories.g.dart` を import する)と同じく、**実在する宣言をアンカーにし、生成物はアンカーファイル自身が import する**:

```dart
// lib/showfase.dart — カタログアプリのエントリポイント
import 'package:flutter/material.dart';
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

import 'showfase.g.dart'; // 生成物(standalone ライブラリ)

@ShowfaseRoot()
void main() => runApp(ShowfaseApp(previews: showfasePreviews()));
```

`flutter run -t lib/showfase.dart` でカタログアプリがそのまま起動する。既存アプリの Widget にアノテートしたい場合はクラスにも付与できる(widgetbook 型):

```dart
@ShowfaseRoot()
class ShowfaseCatalogApp extends StatelessWidget {
  const ShowfaseCatalogApp({super.key});
  @override
  Widget build(BuildContext context) => ShowfaseApp(previews: showfasePreviews());
}
```

初回は `showfase.g.dart` が未生成のため IDE 上はエラーになるが、`dart run build_runner build` の 1 回目で解消される(auto_route / widgetbook と同じブートストラップ手順。README に明記)。

Showkase の「root 未設定は実行時エラー」への反省として、`@ShowfaseRoot` が見つからない場合・複数ある場合は**ビルド時に明確なエラーメッセージ**を出す。

## 4. `showfase_generator`

pure Dart。flutter には依存しない(§1.4)。widgetbook/injectable と同型の 2 フェーズ集約ビルダー。

### 4.1 build.yaml(パッケージ側)

```yaml
builders:
  preview_scanner:
    import: "package:showfase_generator/builder.dart"
    builder_factories: ["previewScannerBuilder"]
    build_extensions: {".dart": [".showfase.json"]}
    auto_apply: dependents
    runs_before: [":showfase_builder"]
    build_to: cache
  showfase_builder:
    import: "package:showfase_generator/builder.dart"
    builder_factories: ["showfaseBuilder"]
    build_extensions: {".dart": [".g.dart"]}
    auto_apply: dependents
    build_to: source          # 生成ファイルをコミットできる
```

### 4.2 Phase 1: `preview_scanner`(per-library、インクリメンタル)

1. `buildStep.inputLibrary` を resolve し、**トップレベル関数・クラスの static メソッド・コンストラクタ/ファクトリ**を走査(source_gen の `LibraryReader.annotatedWith` はトップレベルしか見ないため、クラスメンバは自前で traverse する)
2. アノテーション判定: `TypeChecker.typeNamedLiterally('Preview', inPackage: 'flutter')` と同 `'MultiPreview'` の **assignable 判定**(サブクラスアノテーションを含めて拾う)。1 要素に複数の `@Preview` がスタックされていれば各々 1 エントリ
3. 要素の妥当性検証(flutter_tools と同一ルール): public / 必須引数なし / 戻り値型が `Widget` or `WidgetBuilder`(コンストラクタは常に OK)。違反は `log.warning` でスキップ(理由を明示)
4. 1 エントリにつき以下を JSON 化して `.showfase.json` に出力(マッチ 0 件なら出力しない — `findAssets` を軽く保つ):

```jsonc
{
  "function": "MyWidget.preview",        // 修飾名(flutter_tools と同形式)
  "libraryUri": "package:app/src/button.dart",
  "kind": "constructor",                 // topLevelFunction | staticMethod | constructor
  "isBuilder": false,                    // WidgetBuilder 戻りか
  "isMultiPreview": false,
  "line": 12, "column": 1,
  "annotation": { /* 定数ツリー(§4.3) */ }
}
```

### 4.3 定数ツリー: アノテーションのシリアライズ形式

flutter_tools の `DartObject.toExpression()`(§1.2)を **JSON を経由する 2 段階**に分解する。Phase 1 で `DartObject` を再帰的に pure-data ツリーへエンコードし、Phase 2 でツリーから `code_builder` の const 式を再構築する:

```jsonc
// @Preview(name: 'Primary', size: Size(200, 100), brightness: Brightness.dark,
//          wrapper: AppScope.wrap)  のエンコード例
{
  "type": "instance",
  "class": {"name": "Preview", "libraryUri": "package:flutter/src/widget_previews/widget_previews.dart"},
  "constructor": "",                     // 名前付き ctor なら名前
  "positional": [],
  "named": {
    "name":  {"type": "string", "value": "Primary"},
    "size":  {"type": "instance", "class": {"name": "Size", "libraryUri": "dart:ui"},
              "positional": [{"type": "double", "value": 200}, {"type": "double", "value": 100}]},
    "brightness": {"type": "enum", "class": {"name": "Brightness", "libraryUri": "dart:ui"}, "value": "dark"},
    "wrapper": {"type": "tearoff", "name": "AppScope.wrap", "libraryUri": "package:app/scopes.dart"}
  }
}
```

対応ノード型: `null` / `bool` / `int` / `double` / `string` / `list` / `enum` / `tearoff`(`toFunctionValue()` 由来)/ `instance`(`constructorInvocation` から再帰)。カスタム `MultiPreview` サブクラス(例: `@BrightnessPreview()`)は `instance` ノード 1 個になるだけで、`previews` の中身を静的に評価する必要がない — **実行時に `.transform()` が展開する**。これがこの方式の最大の利点。

エンコード/デコードは pure function として切り出し、単体でゴールデンテスト可能にする。エンコード不能な定数(想定外の型)はその preview をエラーメッセージ付きでスキップ。

### 4.4 Phase 2: `showfase_builder`(集約)

`GeneratorForAnnotation<ShowfaseRoot>`。

1. `@ShowfaseRoot` の一意性検証(0 個 → ビルドエラーで案内、アンカーファイル以外に複数 → エラー)
2. `buildStep.findAssets(Glob('**.showfase.json'))` で全中間 JSON を収集、`libraryUri` + `function` + `line` でソート(生成の決定性・diff 安定性のため)
3. `code_builder`(`DartEmitter.scoped`、プレフィックス import)で以下を出力:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implementation_imports
import 'package:flutter/widget_previews.dart' as _i1;
import 'package:showfase/showfase.dart' as _i2;
import 'package:app/src/button.dart' as _i3;
import 'package:app/src/themes.dart' as _i4;

List<_i2.ShowfasePreview> showfasePreviews() => [
      // 通常の @Preview → const 式を再出力し .transform() を実行時に呼ぶ
      _i2.buildShowfasePreview(
        id: 'package:app/src/button.dart#buttonPreview#0',
        scriptUri: 'package:app/src/button.dart',
        line: 12,
        column: 1,
        transformedPreview:
            const _i1.Preview(name: 'Primary', group: 'Buttons').transform(),
        previewFunction: () => _i3.buttonPreview(),
      ),
      // MultiPreview 派生 → 実行時に transform() で展開してスプレッド
      ..._i2.buildShowfaseMultiPreview(
        id: 'package:app/src/card.dart#cardPreview',
        scriptUri: 'package:app/src/card.dart',
        line: 8,
        column: 1,
        multiPreview: const _i4.BrightnessPreview(),
        previewFunction: () => _i3.cardPreview(),
      ),
    ];
```

4. `dart_style` の `DartFormatter` で整形。`// GENERATED CODE - DO NOT MODIFY BY HAND` ヘッダ + `ignore_for_file` で analyzer/lint クリーンを保証

### 4.5 エンドユーザーの build.yaml(README に記載する設定例)

```yaml
targets:
  $default:
    builders:
      showfase_generator:preview_scanner:
        generate_for:
          include: ["lib/**"]
          exclude: ["lib/**.g.dart"]
```

### 4.6 マルチパッケージ(v1 の割り切り)

`findAssets` は自パッケージのアセットが対象のため、v1 の自動集約は**アプリパッケージ内**に限る。ワークスペース内の別パッケージ(デザインシステムパッケージ等)は、各パッケージに `@ShowfaseRoot` を置いてそれぞれ生成し、手動合成する:

```dart
List<ShowfasePreview> allPreviews() => [...app.showfasePreviews(), ...uiKit.showfasePreviews()];
```

Showkase の「root モジュールの classpath 依存に暗黙で従う」問題の、明示的で単純な代替。README に明記する。

## 5. `showfase`(ランタイム)

Flutter 依存(>=3.38)。`dart:io` 非依存(モバイル/デスクトップ/Web 全対応)。

### 5.1 モデルと build ヘルパー

flutter_tools の `WidgetPreview` / `buildWidgetPreview` / `buildMultiWidgetPreview` と同型:

```dart
class ShowfasePreview {
  const ShowfasePreview({
    required this.id,           // 安定キー(URI#function#index)
    required this.builder,      // Widget Function() — クロージャ保持(Showkase 方式)
    required this.previewData,  // transform() 適用済みの Preview
    this.scriptUri, this.line, this.column,
  });
  final String id;
  final Widget Function() builder;
  final Preview previewData;    // group/name/size/textScaleFactor/wrapper/theme/brightness/localizations
  final String? scriptUri;
  final int? line;
  final int? column;

  String get group => previewData.group;
  String? get name => previewData.name;
}

ShowfasePreview buildShowfasePreview({required Preview transformedPreview,
    required Object? Function() previewFunction, ...});
    // WidgetBuilder 戻りは Builder(builder: fn()) でラップ(flutter_tools と同一)

Iterable<ShowfasePreview> buildShowfaseMultiPreview({required MultiPreview multiPreview, ...});
    // multiPreview.transform() を展開し、index を id に付与
```

`Preview` インスタンスをそのまま保持する(独自モデルへの変換はしない)。理由: `transform()` 済みサブクラスの `wrapper`/`theme`/`localizations` を型情報ごと保持でき、将来の `Preview` フィールド追加にも生成器の変更なしで追従しやすい。

### 5.2 ブラウザ UI

```dart
/// runApp(const ShowfaseApp(previews: ...)) だけで完結するスタンドアロンアプリ
class ShowfaseApp extends StatelessWidget {
  const ShowfaseApp({required this.previews, this.title = 'Showfase', this.theme, this.darkTheme});
}

/// 既存アプリに埋め込める素の Widget(MaterialApp を持たない)
class ShowfaseBrowser extends StatefulWidget { ... }
```

画面構成(Showkase の navigation を踏襲、Navigator 2.0 は使わず素の Navigator で軽量に):

1. **グループ一覧** — `previewData.group` で groupBy、件数バッジ付き。グループが 1 つだけなら自動スキップ(Showkase の `startDestination()` 方式)
2. **グループ内プレビュー一覧** — 各 preview を実描画のサムネイルカード(`IgnorePointer` + `FittedBox`)で表示
3. **プレビュー詳細** — 本命画面。以下を表示・操作:
   - `size` の反映: 幅/高さそれぞれ `double.infinity` なら widget 自身に任せる(`Size.fromHeight`/`fromWidth` 対応、flutter_tools のセマンティクス通り)
   - **明暗切替**: system / light / dark のトグル。`previewData.brightness` を初期値とし、`theme` コールバックがあれば `PreviewThemeData.themeForBrightness()` の結果を `Theme`/`CupertinoTheme` として適用
   - **テキストスケール**: スライダー(0.5–3.0)。初期値 `previewData.textScaleFactor ?? 1.0`。`MediaQuery.copyWith(textScaler:)` で適用
   - **RTL 切替**(Showkase の permutation より): `Directionality` オーバーライド
   - `wrapper` 適用: `previewData.wrapper!(builder())`
   - `localizations` 適用: `Localizations` + delegates + locale 切替ドロップダウン
   - ソース位置(`scriptUri:line`)の表示
4. **検索** — AppBar の検索フィールド。`name`/`group` の部分一致。検索状態は画面遷移をまたいで保持

環境オーバーライドの合成順(内→外): widget → `wrapper` → `Theme`(theme/brightness)→ `Localizations` → `MediaQuery`(textScaler)→ `Directionality` → size 制約。これを 1 つの `ShowfasePreviewCanvas` Widget に切り出し、単体で widget テスト可能にする。

## 6. `packages/showfase/example`

- `@Preview` 各バリエーション(トップレベル / static / コンストラクタ / factory / `WidgetBuilder` 戻り / group / size / textScaleFactor / brightness / wrapper / theme / localizations)
- カスタム `MultiPreview` 派生(`BrightnessPreview`)とスタック `@Preview` の両方
- `lib/showfase.dart`(`@ShowfaseRoot` 付き `main` — カタログのエントリポイント)+ コミット済み `lib/showfase.g.dart`。`flutter run -t lib/showfase.dart` で起動
- web / iOS / Android / macOS を有効化(dart:io 非依存の確認を CI 的に `flutter build web` で担保)

## 7. テスト戦略

| 対象 | 手法 |
|---|---|
| 定数ツリーの encode(DartObject→JSON) | `build_test` の `resolveSources` で実 resolve した要素に対する単体テスト |
| 定数ツリーの decode(JSON→code_builder 式) | pure function として `equalsDart` ゴールデン |
| ビルダー E2E | `testBuilders` で 2 ビルダーを通し、fake `package:flutter/widget_previews.dart` スタブ(Widget/WidgetBuilder/Size/Brightness/Preview/MultiPreview の最小定義)をアセットに入れて `showfase.g.dart` 全文をゴールデン比較 |
| per-element 抽出の網羅(バリデーション・スキップ理由) | 同上の資産で `source_gen_test` 併用(適する範囲で) |
| ランタイム | `ShowfasePreviewCanvas` の widget テスト(brightness/textScale/RTL/wrapper/size 反映)、ブラウザの検索・ナビゲーションのテスト |
| example | 生成ファイルが最新であることの検証(`build_runner build` 後に `git diff --exit-code` 相当を melos script 化) |

fake flutter スタブ方式は widgetbook 等でも使われる標準手法で、テストが Flutter SDK の解決に依存しない利点がある。

## 8. リスクと対応

1. **`widget_previews` は明示的に実験的 API**(「will change」)。→ showfase の Flutter SDK 制約を狭く保ち(`>=3.38.0 <3.45.0` のような上限付き)、Flutter の stable リリースごとに追従リリースする運用を README に明記
2. **`PreviewThemeData` の abstract 化が次期 stable で確定**(PR #188176)。→ v1 は現 stable の `themeForBrightness()` を使うが、theme 適用ロジックを 1 箇所(`ShowfasePreviewCanvas`)に隔離。次期 stable では `apply(context, child)` 呼び出しに置き換えるだけで済む構造にする。生成器側は const 式再出力方式なので**影響なし**(具象フィールドに依存しない)
3. **source_gen が analyzer 14 未対応**。→ 依存範囲を `analyzer: >=9.0.0 <14.0.0` とし、ワークスペースの lock で実解決を固定
4. **マルチパッケージ自動集約は v1 非対応**(§4.6)。手動合成で回避、v2 検討事項
5. **`Preview` へのフィールド追加**(3.44 以降)。→ 定数ツリーは named 引数を汎用に写すため、未知フィールドも生成コードにそのまま流れる(ランタイムの Flutter が知っていれば動く)。生成器のハードコード面は最小

## 9. 依存バージョン方針(社内ポリシーとの整合)

- ワークスペースの `pubspec.lock` をコミットし、実解決バージョンを固定
- 公開ライブラリの依存制約は pub.dev の慣行上レンジが必要なため、**上限を明示した保守的レンジ**(例: `analyzer: ">=9.0.0 <14.0.0"`, `source_gen: ">=4.0.0 <5.0.0"`)とし、lock で実バージョンを固定する
- 採用バージョンはすべて公開から 7 日以上経過した stable(§1.4 の表の通り、最新群は 2026-05 公開)
- 追加依存はすべてインストールスクリプト/フックを持たない pure Dart パッケージ

※ 公開パッケージの pubspec に完全固定バージョンを書くとユーザー側で解決不能になりやすいため上記としたい。完全固定が必須であれば指示ください。

## 10. 実装プラン(承認後、Opus 4.8 で実施)

1. **M1: ワークスペース骨格** — ルート pubspec(workspace)+ melos、4 パッケージの pubspec/LICENSE/CHANGELOG 雛形、analysis_options(flutter_lints / lints)、`mise` の Flutter 3.41.6 を使う `.mise.toml`
2. **M2: showfase_annotation** — `ShowfaseRoot`(30 分規模)
3. **M3: showfase ランタイム(モデル+ヘルパー)** — `ShowfasePreview` / `buildShowfasePreview` / `buildShowfaseMultiPreview` + 単体テスト
4. **M4: showfase_generator** — 定数ツリー encode/decode → scanner → 集約 generator → build.yaml、`testBuilders` E2E ゴールデン
5. **M5: showfase ブラウザ UI** — `ShowfasePreviewCanvas` → 詳細画面 → 一覧/グループ/検索 → `ShowfaseApp`/`ShowfaseBrowser`、widget テスト
6. **M6: example** — プレビュー群、生成実行、`flutter build web` / `flutter test` 確認、生成ファイルコミット
7. **M7: ドキュメント** — 各 README、ルート README(アーキテクチャ図・クイックスタート・build.yaml 例)、pub 公開メタデータ(description/repository/topics)

各マイルストーン完了時に `melos run analyze` / `melos run test` をゲートにする。

## 11. 承認いただきたい判断点

1. アンカー方式: カタログアプリのエントリポイント(`main` 関数または App クラス)に `@ShowfaseRoot` を付与し、そのファイルの隣に standalone の `showfase.g.dart` を生成(auto_route/widgetbook と同型)— 合成入力(`lib/$lib$`)方式より発見性と出力位置の制御に優れるためこちらを推奨
2. 生成戦略: 「const 式の再出力 + 実行時 `transform()`」(flutter_tools 方式)— 静的メタデータ分解方式より互換性・拡張性で優位
3. ベースライン: Flutter 3.38+(3.35 は `group`/`MultiPreview` 非対応のため対象外)
4. マルチパッケージ自動集約は v1 スコープ外(手動合成 API で代替)
5. 依存バージョン方針(§9)
