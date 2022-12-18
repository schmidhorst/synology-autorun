# pacote autorun para Synology NAS
Executa scripts ao ligar armazenamentos externos (USB / eSATA) num NAS Synology com DSM 7.x. O uso típico é copiar ou fazer cópias de segurança de alguns ficheiros.
Em Synologies Task Scheduler existe a possibilidade de criar tarefas desencadeadas. Mas para o evento de disparo só estão disponíveis o Boot-up e o Shutdown. Não há eventos USB disponíveis. Este défice é compensado por esta ferramenta.

## Isenção de Responsabilidade e Rastreador de Problemas
Está a usar tudo aqui por sua conta e risco.
Para questões, utilize o [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) com língua alemã ou inglesa

# Instalação
* Descarregue o ficheiro *.spk de ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" para o seu computador e utilize "Manual Install" no Centro de Pacotes.

Os pacotes de terceiros são restringidos pela Synology no DSM 7. Uma vez que a autorun não requer raiz
é necessária uma etapa manual adicional após a instalação.

SSH ao seu NAS (como utilizador administrativo) e executar o seguinte comando:
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativa ao SSH:
Ir para Painel de Controlo => Agendador de Tarefas => Criar => Tarefa Agendada => Script definido pelo utilizador. No separador "Geral" definir qualquer nome de tarefa, seleccionar "root" como utilizador. No separador "Definições de Tarefas", introduzir
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
como "comando de execução". Termine-o com OK. Quando lhe for pedido para executar agora esse comando durante a instalação do pacote, então vá ao programador de tarefas, seleccione essa tarefa e "Executar".

Em https://www.cphub.net/ no Centro de Pacotes existem [versões mais antigas](https://github.com/reidemei/synology-autorun) para versões mais antigas do DSM:
* DSM 7: na realidade apenas 1,8
* DSM 6: 1.7
* DSM 5: 1.6
* ancião: 1.3

## Créditos e Referências
- Obrigado a [Jan Reidemeister](https://github.com/reidemei) pela sua [Versão 1.8](https://github.com/reidemei/synology-autorun) e pela sua [Licença](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Graças ao [Fórum de Sinologia Thread sobre esse pacote autorun](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Graças a [toafez Tommes](https://github.com/toafez) e ao seu [Pacote Demo](https://github.com/toafez/DSM7DemoSPK)
- Graças ao [geimist Stephan Geisler](https://github.com/geimist) e à dica de acerto para utilizar o [DeepL API](https://www.deepl.com/docs-api) para traduções para outras línguas.


