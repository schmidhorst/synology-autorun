# Paquete de ejecución automática para Synology NAS
Ejecuta scripts cuando se conectan almacenamientos externos (USB / eSATA) en un Synology NAS con DSM 7.x. El uso típico es copiar o realizar copias de seguridad de algunos archivos.
En el Programador de tareas de Synologies existe la posibilidad de crear tareas activadas. Sin embargo, para el evento de activación sólo están disponibles los eventos de arranque y apagado. No hay eventos USB disponibles. Este déficit se compensa con esta herramienta.

## Descargo de responsabilidad y seguimiento de problemas
Usted está usando todo aquí bajo su propio riesgo.
Para problemas por favor use el [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) con idioma Alemán o Inglés

# Instalación
* Descargue el archivo *.spk de ["Versiones"](https://github.com/schmidhorst/synology-autorun/releases), "Activos" en su equipo y utilice "Instalación manual" en el Centro de paquetes.

Los paquetes de terceros están restringidos por Synology en DSM 7. Dado que la ejecución automática requiere
para realizar su trabajo, se requiere un paso manual adicional después de la instalación.

Conéctese mediante SSH a su NAS (como usuario administrador) y ejecute el siguiente comando:
```shell
sudo cp /var/paquetes/autorun/conf/privilege.root /var/paquetes/autorun/conf/privilege
```
Alternativa a SSH:
Ir a Panel de Control => Programador de Tareas => Crear => Tarea Programada => Script Definido por el Usuario. En la pestaña "General" establezca cualquier nombre de tarea, seleccione 'root' como usuario. En la pestaña "Configuración de la tarea" introduzca
```shell
cp /var/paquetes/autorun/conf/privilegio.root /var/paquetes/autorun/conf/privilegio
```
como "Ejecutar comando". Finaliza con OK. Cuando se le pida que ejecute ese comando ahora durante la instalación del paquete, vaya al programador de tareas, seleccione esa tarea y "Ejecútela".

En https://www.cphub.net/ en el Centro de Paquetes hay [versiones antiguas](https://github.com/reidemei/synology-autorun) para versiones antiguas de DSM disponibles:
* DSM 7: en realidad sólo 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder 1.3

## Créditos y referencias
- Gracias a [Jan Reidemeister](https://github.com/reidemei) por su [Versión 1.8](https://github.com/reidemei/synology-autorun) y su [Licencia](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Gracias a [Synology Forum Thread about that autorun package](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Gracias a [toafez Tommes](https://github.com/toafez) y su [Paquete de demostración](https://github.com/toafez/DSM7DemoSPK)
- Gracias a [geimist Stephan Geisler](https://github.com/geimist) y su consejo de usar la [API de DeepL](https://www.deepl.com/docs-api) para traducciones a otros idiomas.

