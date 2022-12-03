# autorun
Executar scripts ao conectar o armazenamento externo (USB / eSATA) em um NAS Synology. O uso típico é para copiar ou fazer backup de alguns arquivos. 
No Agendador de Tarefas de Synology é possível criar tarefas disparadas, mas para o evento disparador só está disponível o Boot-up e o Shutdown. Não há eventos USB disponíveis. Este déficit é compensado por esta ferramenta.  

# instalar
* Baixe o arquivo *.spk de "Releases", "Assets" em Github e use "Manual Install" no Centro de Pacotes.

Em https://www.cphub.net/ no Centro de Pacotes há versões mais antigas para versões mais antigas do DSM disponíveis:
* DSM 7: na verdade ainda só 1.8
* DSM 6: 1,7
* DSM 5: 1.6
* ancião: 1.3

Pacotes de terceiros são restritos pela Synology no DSM 7. Uma vez que a autorun não requer raiz 
para realizar seu trabalho, uma etapa manual adicional é necessária após a instalação.

SSH ao seu NAS (como usuário administrador) e executar o seguinte comando:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativa ao SSH: 
Goto Control Panel => Programador de Tarefas => Criar => Tarefa Programada => Roteiro definido pelo usuário. Na aba "Geral" defina qualquer nome de tarefa, selecione "raiz" como usuário. Na aba "Configurações de Tarefas", digite  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
como "comando de execução". Termine com OK. Quando você for solicitado a executar esse comando agora durante a instalação do pckage, então vá até o agendador de tarefas, selecione essa tarefa e "Run". 

