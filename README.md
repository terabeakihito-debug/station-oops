# STATION OOPS — 初期プロジェクト構成

STATION OPS（完結済みアイドルゲーム）の後日談。Godot 4.7 / GDScript 2D アクションプラットフォーマー。

## フォルダ構成

```
STATION_OOPS/
├── project.godot
├── icon.svg
├── scenes/
│   ├── levels/   Level_00_Boot.tscn （Player+Echo配置済みの動作確認シーン、main_scene指定先）
│   ├── player/   Player.tscn（当たり判定・カメラ・InteractArea・AnimatedSprite2D実装済み）
│   ├── echo/     Echo.tscn（AnimatedSprite2D・ScanArea/GlowLight実装済み）
│   ├── boss/     NOA.tscn（AnimatedSprite2D・フェーズ管理・HitboxArea・ECHOスキャン対応実装済み）
│   └── ui/       HUD.tscn（体力バー・スキャン結果表示、EventBus経由で自動更新）
├── scripts/
│   ├── autoload/ GameManager.gd / EventBus.gd / SaveSystem.gd（project.godotで自動登録済み）
│   ├── player/   Player.gd（移動・ジャンプの雛形）
│   ├── echo/     Echo.gd（追従・コマンド受付の雛形）
│   ├── boss/     NOA.gd（フェーズ管理の雛形）
│   ├── resources/ SaveData.gd（セーブデータResource）
│   ├── levels/   （ステージ固有スクリプトを今後配置）
│   └── ui/       HUD.gd（体力バー・スキャン結果の更新ロジック）
├── assets/
│   ├── sprites/{player,echo,boss,tiles}
│   ├── audio/{bgm,se}
│   └── fonts/
└── data/         （バランス調整用のResource/JSON等を今後配置）
```

## セットアップ手順
1. `STATION_OOPS/` フォルダごとGodot 4.7の「プロジェクトをインポート」で開く
2. `scenes/levels/Level_00_Boot.tscn` を実行
   - A/D または矢印キーで移動、Spaceでジャンプ、床（Floor）の上に立てるか確認
   - Qキーを押すとECHOが一瞬グロー発光（スキャン処理の動作確認）
   - ECHOはプレイヤーに追従する
   - 画面右側のNOA（赤い五角形）に近づいてQを押すと、`ScanArea`がNOAを検知し`on_scanned()`が呼ばれる（現状は内部フラグが立つのみ、外部への表示はまだ無い）
   - NOAにさらに近づいてJを押すと攻撃判定（AttackArea）が発生するが、**NOAは仕様変更によりダメージを受けない**（OOPS core再設計に伴い体力・反撃システムは廃止。詳細は「OOPS core フェーズ1」セクション参照）
   - 画面左上にプレイヤーの体力バー、Qでスキャンすると画面右上にNOAの体力バーが出現、少し下にスキャン結果メッセージが一時表示される

## 入力マップ（キー割当済み）
project.godot に以下のキーを割り当て済み。エディタの「プロジェクト設定→入力マップ」でいつでも変更可能。

| アクション | キー |
|---|---|
| `move_left` | A / ← |
| `move_right` | D / → |
| `jump` | Space |
| `dash` | Shift |
| `interact` | E |
| `echo_command` | Q |
| `attack` | J |

## スプライトについて（NovelAI生成素材の取り込み）
- 元データはいずれもNovelAI生成の1280×1280 PNG（透過背景）
- **重要な訂正**：元画像は「同じポーズを25回繰り返したグリッド」ではなく、**5×5（256×256セル）＝25フレームの本物のアニメーションスプライトシート**だった。最初の実装では1セル目しか取り出しておらず、歩行等のアニメーションが1枚絵のまま止まって見える不具合があったため、全キャラ分を作り直した
- 処理方法：各PNGから25フレームすべてを抽出→キャラごとに全フレーム・全ポーズ共通の統合バウンディングボックスでクロップ→指定の高さにリサイズ→5×5グリッドのシート画像として再構成（`assets/sprites/*/*_sheet.png`）。Godot側は`AtlasTexture`で各シートの25領域を切り出し、`SpriteFrames`の各アニメーションに25フレームを設定している
- フレーム順は元画像のグリッド順（行優先、左上→右下）をそのままアニメーション順として採用（AutoSprite.io等の一般的な書き出し順を想定した仮定）。実際の見え方がおかしい場合はフレーム順の並べ替えが必要
- **Player**（セルサイズ143×140）：idle/walk/jump/fall/kneel/pickup/pull/push/victoryの9アニメーション。`Player.tscn`の`AnimatedSprite2D`は`position=(0,-42)`（scaleは不要、シート自体を等倍サイズで書き出し済み）
- **ECHO**（セルサイズ124×90）：float/point/wave/victoryの4アニメーション。`float`が基本ループ、`point`はスキャン時、`victory`はNOA撃破時に自動再生
- **NOA**（セルサイズ234×220）：float/correct/incorrect/defeatの4アニメーション。`float`が基本ループ、被弾時は点滅演出、撃破時defeat自動再生。correct/incorrectは`play_quiz_reaction(true/false)`で呼び出し可能（フェーズ2クイズ演出用、出題内容は未確定）
- 各アニメーションの再生速度（speed）・ループ有無は暫定値。実際の見た目を見て調整が必要
- いずれも仮の`position`。実際にエディタで表示して微調整が必要

## タイルセット・ステージについて
- `assets/tilesets/stage_tiles.tres`：4種のステージタイル（各128×128、全面コリジョン付き）をAtlasSourceとして登録
  - source 0: `tile_stage0.png`（チュートリアル整備室、ミント系）
  - source 1: `tile_fliplab.png`（FLIP LAB、紫-シアン系）
  - source 2: `tile_wirebay.png`（WIRE BAY、黄-オレンジ系）
  - source 3: `tile_sizedock.png`（SIZE DOCK、緑系）
- `scenes/levels/Level_01_Tutorial.tscn`：チュートリアル整備室の簡易テストレベル。`scripts/levels/Level01.gd`が`_ready()`で`TileMapLayer.set_cell()`を呼んでタイルを配置している
  - **手書きでTileMapLayerの`tile_data`を直接記述するのは避けた**：Godot内部のビット詰め込み形式に依存し壊れやすいため、スクリプトで組み立てる方式にした
  - `Ground`レイヤー：床を横10タイル敷き詰め（y=5行目）
  - `Platforms`レイヤー：ジャンプ練習用の浮き足場を3枚
- FLIP LAB実装済み（下記）。WIRE BAY/SIZE DOCK/OOPS coreの実レベルはまだ未着手（タイルセットの登録のみ完了）
- [x] ジャンプ到達高さの調整：`jump_velocity=-420`では最大到達高さが約90pxしかなく、1タイル(128px)にも届かなかったため`-770`に変更（最大到達高さ約302px、2タイル上の足場にも余裕を持って届く）。あわせて`jump`アニメーションのspeedも新しい頂点到達時間（約0.79秒）に合わせて8.9に再調整。足場の高さも1〜2タイル上（床から128px/256px）に調整

## FLIP LAB（重力反転ギミック）について
- `scenes/levels/Level_02_FlipLab.tscn`：床（`Ground`、y=5行目）と天井（`Ceiling`、y=1行目）の両方にタイルを敷いたステージ。`scripts/levels/Level02.gd`が`_ready()`で配置
- `scenes/levels/GravityFlipPad.tscn` + `scripts/levels/GravityFlipPad.gd`：踏むと`toggle_gravity()`を持つ相手（プレイヤー）の重力を反転させるArea2D。紫の板＋シアンの縁取りで視覚化（FLIP LABのテーマカラー）
- `Player.gd`に`gravity_dir`（1=通常/-1=反転）を追加し、`toggle_gravity()`で反転を実装：
  - Godot標準の`up_direction`プロパティを反転（`Vector2(0, -gravity_dir)`）することで、`is_on_floor()`が反転後の「床（＝元の天井）」を正しく検知するようにしている
  - 重力加速度・ジャンプ初速の両方に`gravity_dir`を掛けて向きを反映
  - `AnimatedSprite2D.flip_v`で見た目も上下反転
  - 連続トリガー防止のクールダウン（0.5秒）付き
- 床側・天井側それぞれにパッドを1枚ずつ配置（踏むたびに反転をトグル）
- 今後の拡張候補：反転中に専用の演出（パーティクル等）を入れる、パッドを踏んだ瞬間の慣性（`velocity.y = 0`にリセットしている）をもう少し自然にする、等

## WIRE BAY（ワイヤー引っ張りギミック）について
- `scenes/levels/Level_03_WireBay.tscn`：床の途中に隙間（x=512〜1024）があるステージ。`scripts/levels/Level03.gd`が`_ready()`で左右の床タイルのみ配置
- `scenes/levels/WireHook.tscn` + `scripts/levels/WireHook.gd`：Eキーでインタラクトすると`WirePlatform`をワイヤーで引き寄せるArea2D。`Line2D`でフックと足場の間にワイヤーを常時描画（`_process()`で毎フレーム更新）
- `scenes/levels/WirePlatform.tscn`：引き寄せられる可動足場（`AnimatableBody2D`、`sync_to_physics=true`でプレイヤーを正しく乗せて運べるようにしている）。オレンジ系でWIRE BAYのテーマカラーに
- プレイヤー側：`Player.gd`に汎用の`lock_animation(anim_name, duration)`を追加し、引き寄せ中は`pull`アニメーション（以前フレーム検証のみ済みで未使用だったループ動作）を再生。既存の`_is_attacking`と同様の仕組みで`_external_lock_time`の間だけ状態切替をブロックしている
- 初期配置：足場は隙間の先の届かない位置（x=1400）にあり、フックをインタラクトすると`pull_offset`分（-700, 0）移動して隙間（x=512〜1024）を橋渡しする
- **ハマりやすい点**：`WireHook`のようにPlayerの`InteractArea`から検知されたいArea2Dは`monitorable=true`にする必要がある（`monitoring`ではなく）。最初これを取り違えて動作しなかった

## SIZE DOCK（サイズ切替ギミック）について
- `scenes/levels/Level_04_SizeDock.tscn`：連続した床の途中に低い通路（`LowCeiling`）があるステージ。`scripts/levels/Level04.gd`が`_ready()`で床タイルを配置
- `scenes/levels/SizeTogglePad.tscn` + `scripts/levels/SizeTogglePad.gd`：踏むと`toggle_size()`を持つ相手（プレイヤー）の大きさを切り替えるArea2D。緑の板＋薄緑の縁取りでSIZE DOCKのテーマカラー
- `Player.gd`に`size_mode`（"normal"/"small"）と`toggle_size()`を追加。**Playerノード自体を`scale`させる方式**にすることで、コリジョン・スプライト・InteractArea/AttackAreaなど子ノードをまとめて縮小/復元している（個別にシェイプを書き換える必要がない）
  - 縮小率は`small_scale`（デフォルト0.55）でエクスポート済み
  - 連続トリガー防止のクールダウン（0.5秒）付き
- `LowCeiling`：通常サイズだと頭がぶつかって通れず、`small_scale=0.55`まで縮むとくぐれる高さ（隙間約45px）に調整済み
- 通路の手前と奥にパッドを1枚ずつ配置（手前で縮小→通路をくぐる→奥で元のサイズに復元）

## プレイヤー名前入力について
- `scenes/ui/NameInput.tscn` + `scripts/ui/NameInput.gd`：ゲーム開始直後に出す想定の名前入力画面
- 画面上のオンスクリーンキーボード（QWERTY配列のA-Zボタン、`_build_keyboard()`で実行時に生成）で3〜8文字を入力
- `GameManager.set_player_name()`で3〜8文字のバリデーション込みで保存（`GameManager.player_name_input`、OOPS coreフェーズ3のクロスワードで使用予定）
- 確定すると`EventBus.player_name_confirmed`シグナルを発火
- **修正済み**：確定後は`Level_01_Tutorial.tscn`に遷移する（旧: 暫定でLevel_00_Bootに遷移していたが、ステージ間の繋がりができたため本来の最初のステージへ変更）
- 単体で動作確認したい場合は`NameInput.tscn`を直接開いてF6で実行すればよい

## タイトル画面について
- `scenes/ui/TitleScreen.tscn` + `scripts/ui/TitleScreen.gd`：アップロードいただいたキービジュアル（`assets/sprites/ui/title_key_visual.png`）を全画面背景に使用
- 画面下部に明滅する「PRESS ANY KEY TO START」表示。キー入力またはクリックで`NameInput.tscn`へ遷移
- `project.godot`の`main_scene`を`TitleScreen.tscn`に変更済み。これで「タイトル→名前入力→チュートリアル→FLIP LAB→WIRE BAY→SIZE DOCK→OOPS core」という一連の流れが繋がった

## ステージ間の遷移について
- **重要なバグ修正**：各ステージにゴール（出口）が一つも実装されておらず、チュートリアルから先に進めない状態になっていた
- `scenes/levels/LevelExit.tscn` + `scripts/levels/LevelExit.gd`：ステージクリア地点。プレイヤー（`"player"`グループに所属）が触れると`next_scene_path`（インスペクタで設定するシーンファイルパス）へ`change_scene_to_file()`で遷移する汎用シーン
- 各ステージの右端（x=1200付近）に配置し、以下の順で繋いだ：
  `Level_01_Tutorial → Level_02_FlipLab → Level_03_WireBay → Level_04_SizeDock → Level_05_OOPSCore`
- `NameInput.gd`の名前確定後の遷移先も、暫定の`Level_00_Boot`から`Level_01_Tutorial`に修正した
- **重要なバグ修正**：チュートリアルの足場の1枚（列9・row4）が床の真上に隙間ゼロで置かれていたため、その列が実質的な壁になり出口（LevelExit、x=1200）まで地上を歩いて辿り着けなかった。該当の足場を列7に移動して通路を確保した
- **バグ修正**：`LevelExit`が物理コールバック（`body_entered`）中に直接`change_scene_to_file()`を呼んでいたため、「物理コールバック中にコリジョンノードを削除している」というエラーが発生していた。`call_deferred()`でシーン切り替えを1フレーム遅延させて解消

## OOPS core（最終ボス戦）について
- **企画決定事項**：フェーズ1=ヒント収集、フェーズ2=バズァークイズ（雑学3問）、フェーズ3=クロスワード（プレイヤー名のワードのみ完成すればOK）。**NOAの体力・攻撃・反撃システムは廃止**し、ダメージ概念のない「パズル完了で次フェーズへ」という進行方式に変更した（旧`take_damage`/`CounterAttackArea`/`HitboxArea`は`NOA.gd`/`NOA.tscn`から削除済み）
- `scripts/boss/NOA.gd`：`Phase`列挙型を`PHASE_1/PHASE_2/PHASE_3/DEFEATED`に拡張。`enter_phase_2()`/`enter_phase_3()`/`defeat()`をレベル側から呼んで進行させる公開メソッドに変更
- **フェーズ1（今回実装）**：
  - `scenes/boss/HintObject.tscn` + `scripts/boss/HintObject.gd`：破壊可能なヒントオブジェクト（`take_damage`/`health`を持つ`StaticBody2D`）。破壊されると`GameManager.collect_hint()`を呼んで消滅
  - `GameManager.collected_hints`（`Array[String]`）でヒント収集状況を管理。`TOTAL_HINT_COUNT=5`個集まると`EventBus.all_hints_collected`を発火
  - `scenes/levels/Level_05_OOPSCore.tscn`：NOA＋ヒントオブジェクト5個＋Player/Echo/HUDを配置したアリーナ。`scripts/levels/Level05.gd`が`all_hints_collected`を受けて`NOA.enter_phase_2()`を呼ぶ
  - ヒントの文字（`hint_letter`）は現状仮の値（A〜E固定）。実際はプレイヤー名（3〜8文字）の各文字に対応させる想定なので、フェーズ3実装時に`GameManager.player_name_input`から動的に割り当てる形へ調整が必要
- `scripts/ui/HUD.gd`：旧`BossHealthPanel`（体力バー）を`BossPhasePanel`（フェーズ名＋ヒント進捗表示）に置き換え
- **未実装**：フェーズ3（クロスワードUI・判定ロジック）

## OOPS core フェーズ2（バズァークイズ）について
- `scenes/ui/QuizUI.tscn` + `scripts/ui/QuizUI.gd`：雑学3問を制限時間8秒/問の早押し選択式で出題
- `Level05.gd`が`all_hints_collected`を受けて`NOA.enter_phase_2()`を呼んだ直後に`QuizUI`をインスタンス化して表示
- 正解/不正解は`NOA.play_quiz_reaction(true/false)`で演出（`correct`/`incorrect`アニメーション）するが、**正誤にかかわらず3問終われば次フェーズへ進む**設計（テンポ重視。厳密な合否判定にしたい場合は`QuizUI.gd`の`quiz_completed`発火条件を調整すればよい）
- 時間切れは不正解と同じ扱い
- 全問終了後、`QuizUI`は`quiz_completed`を発火して自身を消滅させ、レベル側が`NOA.enter_phase_3()`を呼ぶ
- 出題内容（`QUESTIONS`定数）は仮の3問。実際に採用したい問題があれば`QuizUI.gd`内の配列を差し替えるだけでよい

## OOPS core フェーズ3（クロスワード）について
- `scenes/ui/CrosswordUI.tscn` + `scripts/ui/CrosswordUI.gd`：企画決定「全マス埋める必要はなくプレイヤー名のワードだけ完成すればクリア」を踏まえた簡易実装
- `GameManager.player_name_input`の文字をシャッフルしてボタンとして提示し、正しい順番でクリックしていくと名前が完成する方式（名前入力画面が未通過など`player_name_input`が空の場合は"NOA"をフォールバックとして使用）
- 間違った文字を押しても進行が壊れないよう「違う…もう一度」と表示するだけで、正しい文字を選び直せば続行できる寛容な設計
- 完成すると`crossword_completed`を発火して自身を消滅させ、レベル側が`NOA.defeat()`を呼んでボス撃破（`EventBus.boss_defeated`発火、HUDのフェーズ表示が「撃破」に）
- **既知のギャップ**：フェーズ1のヒント収集（5個固定）とプレイヤー名の文字数（3〜8文字）は現状連動していない。ヒントの内容を本当にクロスワードの手がかりとして機能させたい場合は、ヒント数とプレイヤー名の文字数を一致させる設計変更が必要（例：ヒント数をプレイヤー名の文字数に合わせて動的に生成する等）

これでOOPS core（ヒント収集→クイズ→クロスワード→撃破）の一連の流れが最後まで繋がった。

## エンディング画面について
- `scenes/ui/EndingScreen.tscn` + `scripts/ui/EndingScreen.gd`：NOA撃破（`EventBus.boss_defeated`）から2秒後（`Level05.gd`の`ENDING_DELAY`、defeatアニメーションを見せるための間）に自動遷移
- `GameManager.player_name_input`を使って「〇〇さん、おつかれさまでした」を表示
- 何かキーを押す/クリックすると`GameManager.reset_game()`（ヒント・フラグ・名前等をリセット）した上でタイトル画面に戻る
- これで「タイトル→名前入力→5ステージ→OOPS core→エンディング→タイトル」の一周が完成した

## すでに入れてある仕組み


- **オートロード3種**（project.godotに登録済み）
  - `GameManager`：章・フラグ・ECHO信頼度・キャラクターシード（記憶にある固定値）を保持
  - `EventBus`：シーン間シグナルの中継役（プレイヤー/ECHO/ボス系で分類済み）
  - `SaveSystem`：`SaveData`（Resource）を`user://`にセーブ/ロード
- **キャラクタースクリプト雛形**：Player / Echo / NOA（いずれも最小限の骨組みのみ）

## 次のTODO（実装は別途進行）
- [x] ECHOの `.tscn` シーン作成（`scenes/echo/Echo.tscn`）
- [x] プレイヤーの `.tscn` シーン作成（`scenes/player/Player.tscn`）
- [x] NOAの `.tscn` シーン作成（`scenes/boss/NOA.tscn`、ECHOスキャンに`on_scanned()`で反応）
- [x] Boot シーンにPlayer/Echoを配置し、追従・スキャン連携を統合確認できる状態に
- [x] Boot シーンにNOAを配置し、ECHOスキャンでの`on_scanned()`検知を統合確認できる状態に
- [x] プレイヤーの攻撃手段（Jキー、AttackArea）とNOAのHitboxArea/take_damageを接続
- [x] HUD（プレイヤー/NOAの体力バー、スキャン結果表示）の実装
- [x] プレイヤーのスプライト差し替え（NovelAI生成9ポーズ→AnimatedSprite2D、idle/walk/jump/fall自動切替、kneel/pickup/pull/push/victoryは`play_action()`で呼び出し可能）
- [x] ECHOのスプライト差し替え（float/point/wave/victory→AnimatedSprite2D、スキャン時point・NOA撃破時victory自動再生）
- [x] NOAのスプライト差し替え（float/correct/incorrect/defeat→AnimatedSprite2D、被弾点滅・撃破時defeat自動再生、quiz反応は`play_quiz_reaction()`で呼び出し可能）
- [x] NOAの`defeat`アニメーションをAutoSpriteで再生成（`NOA-defeat-v2.png`）。旧版はフレーム13〜16付近に小さな浮遊ノイズ（12〜90px程度の破片）があったため、単体ポーズ画像を開始フレーム指定にして再生成し解消。新版には落ち影が描き込まれているが、他ポーズには影が無い非対称な状態を承知の上でそのまま採用
- [ ] NOAフェーズ2のクイズ演出：内容（出題トピック）は未確定（別チャットで検討）。演出の再生口（`play_quiz_reaction`）は用意済み
- [x] ~~NOAの反撃実装~~ → **仕様変更により廃止**。OOPS core再設計（企画決定）に伴い、NOAの体力・攻撃・反撃システムは全て削除し、ダメージ概念のない3フェーズのパズル/クイズ形式に変更した（詳細は「OOPS core フェーズ1」セクション参照）
- [x] **重要なバグ修正**：プレイヤーの攻撃判定（`_try_attack()`）が`HintObject`（StaticBody2D）に一切当たらない不具合を修正。原因は`Area2D.get_overlapping_bodies()`の監視キャッシュが更新されないことで、座標・コリジョンレイヤー・シェイプサイズは完全に一致しているのに検出できていなかった（`PhysicsShapeQueryParameters2D`による直接の物理クエリでは正しく検出できることをデバッグ出力で確認済み）。`get_overlapping_bodies()`は「継続的に置いておくトリガー範囲」（InteractArea/ScanArea等、プレイヤーが歩いて近づく用途）には向いているが、攻撃のように一瞬だけ判定したいケースには不向きと判明したため、`_try_attack()`を`get_world_2d().direct_space_state.intersect_shape()`による直接クエリ方式に書き換えて解消した。自分自身（Player本体・InteractArea等）を誤検出しないようガードも追加
- [x] プレイヤーの攻撃アニメーション追加（`player-punch.png`、25フレーム。他ポーズと同じ共通クロップ範囲・高さ140pxで統一。ガード→パンチ伸展(フレーム5〜8)→反動→構え直し、という単一の動きで周期の重複は無かったため全25フレームをそのまま使用。loop=false、speed=22）。Jキーで`attack`アニメーションが再生され、再生中は他のアニメーションに切り替わらないようロック（`_is_attacking`フラグ、`animation_finished`で解除）。ただし攻撃判定（ダメージ発生）自体はキー入力の瞬間に発生し、アニメーションのパンチが伸びるタイミングとは同期していない点は今後の調整余地
- [ ] Player/ECHO/NOAの`AnimatedSprite2D`の`position`と各アニメーションの`speed`を実際の見た目に合わせて微調整
- [ ] アニメーションのフレーム順（グリッドの行優先を仮定）が実際の動きと合っているか確認
- [x] ジャンプ時の二段ジャンプ的な見た目の修正（原因は`player-jump.png`の25フレームに「跳ねる動き」が2周期分収録されていたこと。さらにフレーム0は宙に浮いた中途半端な高さだったため、地面に近い屈伸ポーズ〜頂点〜屈伸ポーズが揃うフレーム5〜16の12枚に絞って解決）
- [x] `fall`はフレーム0〜12のみを使用（ループ）。フレーム13〜24は「着地の収まりポーズ」ではなく「仰向けに倒れる」動きだったため、着地アニメーションとしての流用は取りやめ、着地時は素直にidle/walkへ切り替わる形に戻した
- [x] `jump`アニメーションを屈伸〜頂点の上昇部分（フレーム5〜11、7枚）に絞り、speedを16に調整。物理的な頂点到達時間（約0.43秒、`jump_velocity=-420`/`gravity=980`から算出）とアニメーション再生時間を合わせることで、`fall`へ切り替わる前に屈伸に戻る動きが尻切れになる問題を解消
- [x] `fall`は`player_fall_sheet.png`ではなく`player_jump_sheet.png`のフレーム12〜16（頂点→屈伸の下降部分、5枚、loop=false）を使用するよう変更。`jump`(05〜11:屈伸→頂点)と`fall`(12〜16:頂点→屈伸)を合わせることで、元の25フレームのうち屈伸→頂点→屈伸の1周期（フレーム5〜16）がそのまま再現される形になった。`player_fall_sheet.png`自体は現在未使用
- [ ] STATION OPSで使ったレイヤー背景システムを本作にも移植するか検討
