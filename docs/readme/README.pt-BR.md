# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

App nativo SwiftUI para transferir arquivos entre Android e Mac com Apple Silicon por USB. Interface mínima estilo Finder, cor de destaque do sistema, busca nativa e Liquid Glass. É instalado separadamente do Google Android File Transfer.

## Requisitos e instalação

Requer **Apple Silicon / arm64 e macOS 14.0 ou posterior**. Verificado no macOS 27.2 e Galaxy Z Fold7; macOS 28, Intel e outros dispositivos não foram verificados. Execute `dist/MacAndFiles.app` após compilar ou extraia o ZIP e coloque o app em Aplicativos. libmtp/libusb estão incluídos; não é necessário Homebrew ou Android Studio para executar. É uma compilação de desenvolvimento assinada ad-hoc, sem Developer ID ou notarização.

## Conectar e usar

Conecte com cabo USB de dados, desbloqueie Android e selecione “Transferência de arquivos / Android Auto”. Encerre Android File Transfer, seu Agent e outros apps MTP. Busque dispositivos, selecione um e conecte. Depuração USB e ADB não são necessários. Clique duas vezes em pastas; ⌘D salva no Mac, ⌘U envia ao Android; arrastar arquivos do Finder também funciona. ⌘↑ sobe, ⌘⇧N cria pasta e ⌘R atualiza. ⌘F busca nomes apenas na pasta atual; limpar ou Esc restaura a lista. Itens ocultos pela busca são desmarcados. Mais contém ajuda, desconexão e diagnóstico. Revise nomes de arquivos antes de compartilhar registros.

## Idiomas

Segue o idioma preferido do macOS e a configuração por app em Ajustes do Sistema → Geral → Idioma e Região. Reinicie após mudar o idioma. Inclui 13 idiomas; outros usam inglês. Datas, tamanhos e porcentagens seguem a região. Nomes de arquivos e dispositivos são preservados; diagnósticos de bibliotecas podem permanecer em inglês.

## Comportamento de transferência

Nomes existentes interrompem a operação, sem sobrescrever. Downloads usam arquivos temporários e verificam tamanho antes do nome final; uploads verificam o tamanho informado pelo Android. Cancelar ou falhar preserva o que terminou e pode deixar arquivos parciais no Android. Pastas são copiadas recursivamente com profundidade máxima 128; links simbólicos e arquivos especiais são rejeitados. O progresso inclui os arquivos e bytes de toda a operação. Apenas conteúdo exposto por MTP fica acessível; excluir, renomear e montar volumes Finder não são implementados.

## Compilar e verificar

Requer Swift 6.2+, SDK macOS 26+, libmtp 1.1.23 e libusb 1.0.30. O script verifica versões e SHA-256 das fontes, incluindo bibliotecas dinâmicas e fontes correspondentes. O arquivo de fontes exclui builds e diagnósticos privados. Os comandos abaixo são diagnósticos somente leitura, não uma CLI geral de arquivos ou MCP. `--verify-transfer` grava arquivos UUID de teste: desconecte a GUI e use apenas um dispositivo autorizado; verifique possíveis resíduos.

```sh
brew install pkg-config
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
scripts/build-app.sh
scripts/package-source.sh
```

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --diagnose
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --probe
```

## Licenças e contribuições

Código, scripts e documentação: **MIT**. Robô Android: **CC BY 3.0**. libmtp/libusb: **LGPL-2.1-or-later**. Preserve licenças e avisos. Android é marca da Google LLC; este não é um app oficial. MacAndFiles é nome de desenvolvimento: revise marca e notarização antes de publicar. O README inglês é a referência técnica completa. Leia AGENT.md para contribuir. Este fluxo ainda não publicou no GitHub.

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## Terminal e agentes

Após instalar o app, execute `scripts/install-cli.sh` para instalar `maf`. Obtenha os IDs com `maf devices` e `maf storages --device "ID"`. Consulte `maf help` e o [guia da CLI](../CLI.md) para listar, enviar, baixar e criar pastas. A saída é JSON; falhas retornam códigos de erro e status diferente de zero. Desconecte o dispositivo na interface antes de usar a CLI.

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

Compilado para macOS 14+. Testado no macOS 27.2; versões anteriores ainda precisam de testes reais. Liquid Glass no macOS 26+.

Veja arquivos totais e concluídos, progresso geral, velocidade média e tempo restante estimado. Arquivos concluídos são preservados se a transferência parar.

Instale maf em Mais → Terminal e agentes. Se necessário, adicione ~/.local/bin ao PATH. Desconecte a GUI antes de operar pela CLI.

maf compartilha o motor de transferência: resultados JSON, erros estáveis e estado USB claro para scripts e agentes.

[MacAndFiles](https://macandfiles.pages.dev/pt-BR/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
