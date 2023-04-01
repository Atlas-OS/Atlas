<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">パフォーマンスとレイテンシを最適化するように設計された、オープンで透過的なWindowsオペレーテ</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">インストール</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">よくある質問</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">不和</a>
  •
  <a href="https://forum.atlasos.net">フォーラム</a>
</p>

## 🤔 **アトラスとは何ですか？**

Atlasはwindows10の修正版であり、ゲームのパフォーマンスに悪影響を与えるWindowsのすべての負の欠点を取り除きます。 私たちは、あなたがローエンド、またはゲームPCを実行しているかどうか、プレイヤーのための平等な権利のために努力し、透明でオープンソースのプロジ

また、システムレイテンシ、ネットワークレイテンシ、入力レイテンシを削減し、パフォーマンスに焦点を当てながらシステムを非公開にするのにも最適なオプションです。

## 📚 **目次**

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [アトラスプロジェクトとは何ですか？](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Atlasをインストールするにはどうすればよいですか？](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Atlasで削除されるものは何ですか？](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [インストール](https://github.com/Atlas-OS/Atlas/wiki/2.-Installing)
- [インストール後](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [ソフトウェア](https://github.com/Atlas-OS/Atlas/wiki/4.-Software)
- [ブランディングキット](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)
- [リーガル](https://github.com/Atlas-OS/Atlas/wiki/Legal)

## 🆚 **Windows ペア Atlas**

### 🔒 プライベート
Atlasは、Windows内に埋め込まれたすべての種類の追跡を削除し、データ収集を最小限に抑えるために多数のグループポリシーを実装します。 Windowsの範囲外のものは、我々は、このようなあなたが訪問するウェブサイトなどのためのプライバシーを高めることはできません。

### 🛡️ セキュア
Atlasは、パフォーマンスを失うことなく、可能な限り安全であることを目指しています。 これを行うには、情報が漏洩したり悪用されたりする可能性のある機能を無効にします。 これには[Spectre]などの例外があります（https://spectreattack.com/spectre.pdf）、および[メルトダウン]（https://meltdownattack.com/meltdown.pdfこれらの緩和策は、パフォーマンスを向上させるために無効になっています。

セキュリティ緩和策がパフォーマンスを低下させると、無効になります。
以下は変更されたいくつかの機能/緩和策ですが、（P）が含まれている場合は、修正されたセキュリティリスクです:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [リモートデスクトップ](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Posible information retrieval*)

### 🚀 デブロート
アトラスは大きく剥がされ、プリインストールされたアプリケーションやその他のコンポーネントが削除されます。 互換性の問題の可能性があるにもかかわらず、これはISOとインストールサイズを大幅に減少させます。 Windows Defenderなどの機能は完全に削除されます。 

この変更は純粋なゲームに焦点を当てていますが、ほとんどの仕事と教育アプリケーションは機能します。 [私たちは私たちのFAQで削除した他に何をチェックしてください](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### ✅ パフォーマンス
アトラスは事前に調整されています。 互換性を維持するだけでなく、パフォーマンスのために努力しながら、我々は私たちのWindowsイメージにパフォーマンスのすべての最後の 

Windowsを改善するために行った多くの変更のいくつかを以下に示します。

- カスタマイズされた力の機構
- サービスとドライバーの量の削減
- 無効なオーディオ排他
- 不要なデバイスを無効にする
- 無効化された省電力
- パフォーマンスを重視するセキュリティ緩和策が無効になっています
- すべてのデバイスでMSIモードを自動的に有効にする
- ブート構成の最適化
- 最適化されたプロセススケジューリング

## 🎨 ブランディングキット
あなた自身のアトラスの壁紙を作成したいですか？ あなた自身のデザインを作るために私たちのロゴを混乱させるかもしれませんか？ 私たちは、コミュニティ全体で新しい創造的なアイデアを刺激するために、これを一般に公開しています。 [私たちのブランドキットをチェックして、壮大な何かを作る。](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

また、[ディスカッション]タブには[専用エリア]があります。(https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), だから、他の創造的な天才とあなたの作品を共有し、多分いくつかのインスピレーションを刺激することができます!

## ⚠️ Disclaimer (免責事項)
By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). None of these images are pre-activated, you **must** use a genuine key.
