# pacote autorun para Synology NAS
Executa scripts ao conectar armazenamentos externos (USB / eSATA) em um NAS Synology com DSM 7.x. O uso típico é copiar ou fazer backup de alguns arquivos.
Em Synologies Task Scheduler há a possibilidade de criar tarefas acionadas. Mas para o evento de acionamento, só há Boot-up e Shutdown disponíveis. Não há eventos USB disponíveis. Este déficit é compensado por esta ferramenta.

## [Licença](https://htmlpreview.github.io/?https://github.com/schmidhorst/synology-autorun/blob/main/package/ui/licence_ptb.html)

## Isenção de Responsabilidade e Rastreador de Problemas
Você está usando tudo aqui por sua própria conta e risco.
Para questões, use o [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) com o idioma alemão ou inglês

# Instalação
* Baixe o arquivo *.spk de ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" para seu computador e use "Manual Install" no Centro de Pacotes.

Os pacotes de terceiros são restritos pela Synology no DSM 7. Uma vez que a autorun não requer raiz
para realizar seu trabalho, uma etapa manual adicional é necessária após a instalação.

SSH para seu NAS (como usuário administrador) e executar o seguinte comando:
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativa ao SSH:
Ir para Painel de controle => Agendador de tarefas => Criar => Tarefa agendada => Roteiro definido pelo usuário. Na aba "Geral" defina qualquer nome de tarefa, selecione "raiz" como usuário. Na aba "Configurações de Tarefas", digite
casca
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
como "comando de execução". Termine com OK. Quando você for solicitado a executar esse comando agora durante a instalação do pacote, então vá até o agendador de tarefas, selecione essa tarefa e "Executar".

Em https://www.cphub.net/ no Centro de pacotes há [versões anteriores] (https://github.com/reidemei/synology-autorun) para versões anteriores do DSM disponíveis:
* DSM 7: na verdade ainda apenas 1,8
* DSM 6: 1.7
* DSM 5: 1.6
* ancião: 1.3

## Créditos e Referências
- Obrigado a [Jan Reidemeister](https://github.com/reidemei) por sua [Versão 1.8](https://github.com/reidemei/synology-autorun) e sua [Licença](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Graças ao [Fórum de Sinologia Thread sobre esse pacote autorun](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Graças a [toafez Tommes](https://github.com/toafez) e seu [Pacote Demo](https://github.com/toafez/DSM7DemoSPK)
- Graças ao [geimist Stephan Geisler](https://github.com/geimist) e à dica de acerto para usar a [DeepL API](https://www.deepl.com/docs-api) para traduções para outros idiomas.

