# Autoejecución
Ejecuta scripts cuando se conecta un almacenamiento externo (USB / eSATA) en un Synology NAS. El uso típico es copiar o hacer una copia de seguridad de algunos archivos. 
En el Programador de tareas de Synology existe la posibilidad de crear tareas activadas, pero para el evento de activación sólo están disponibles el arranque y el apagado. No hay eventos USB disponibles. Este déficit se compensa con esta herramienta.  

# Instalar
* Descargue el archivo *.spk desde "Releases", "Assets" en Github y utilice "Manual Install" en el Package Center.

En https://www.cphub.net/ en el Centro de Paquetes hay versiones antiguas para las versiones más antiguas de DSM disponibles:
* DSM 7: en realidad todavía sólo 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder 1.3

Los paquetes de terceros están restringidos por Synology en DSM 7. Dado que la ejecución automática requiere permisos de root 
para realizar su trabajo, se requiere un paso manual adicional después de la instalación.

Acceda por SSH a su NAS (como usuario administrador) y ejecute el siguiente comando:

``shell
sudo cp /var/paquetes/autorun/conf/privilegio.root /var/paquetes/autorun/conf/privilegio
```
Alternativa a SSH: 
Ir al Panel de Control => Programador de Tareas => Crear => Tarea Programada => Script Definido por el Usuario. En la pestaña "General" establezca cualquier nombre de tarea, seleccione 'root' como usuario. En la pestaña "Configuración de la tarea" introduzca  
``shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
como "comando de ejecución". Termina con OK. Cuando se le pida que ejecute ese comando ahora durante la instalación de pckage, entonces vaya al programador de tareas, seleccione esa tarea y "Ejecútela". 


Traducción realizada con la versión gratuita del traductor www.DeepL.com/Translator
