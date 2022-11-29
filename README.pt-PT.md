# autorun
Executar scripts ao ligar armazenamento externo (USB / eSATA) num NAS de Synology. O uso típico é copiar ou fazer o backup de alguns ficheiros. 
No Agendador de Tarefas de Synology é possível criar tarefas desencadeadas, mas para o evento de disparo só está disponível o Boot-up e o Shutdown. Não há eventos USB disponíveis. Este défice é compensado por esta ferramenta.  

# instalar
* Descarregar o ficheiro *.spk de "Releases", "Assets" em Github e utilizar "Manual Install" no Centro de Pacotes.

Em https://www.cphub.net/ no Centro de Pacotes estão disponíveis versões mais antigas para versões mais antigas do DSM:
* DSM 7: na realidade apenas 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* ancião: 1.3

Os pacotes de terceiros são restringidos pela Synology no DSM 7. Uma vez que a autorun não requer raiz 
é necessária uma etapa manual adicional após a instalação.

SSH ao seu NAS (como utilizador administrativo) e executar o seguinte comando:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativa ao SSH: 
Goto Control Panelel => Programador de Tarefas => Criar => Tarefa Agendada => Script definido pelo utilizador. No separador "Geral" definir qualquer nome de tarefa, seleccionar "root" como utilizador. No separador "Definições de Tarefas", introduzir  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
como "comando de execução". Termine-o com OK. Quando lhe for pedido para executar agora esse comando durante a instalação do pckage, então vá ao programador de tarefas, seleccione essa tarefa e "Executar". 

