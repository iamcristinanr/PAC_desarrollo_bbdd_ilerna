Ejecutar el script PAC_Desarrollo_2s2223_UF3_Configuracion_Inicial.sql:

- Ejecuta el código que continente la creación de 2 tablas
- Revisa que las dos tablas estan creadas correctamente
- Revisa el contenido que se ha insertado en las tablas
  
 La definición de las tablas es la siguiente:
 
**ASIGNATURAS**
- COD_ASIG – Código único de cada asignatura (PK)
- ABV_ASIG – Abreviatura del nombre de la asignatura
- DES_ASIG – Descripción de la asignatura
- SEMES – Número de semestre en el que se debiera cursar la asignatura
- HORAS – Número de horas que tiene la asignatura
- PONDERA_ASIG – Ponderación que tiene la Asignatura en el ciclo según sus horas
- PRECIO – Precio de la asignatura
- NUM_UFS – Número de Unidades Formativas de la asignatura
  
**UFS**
- COD_ASIG – Código único de cada asignatura (PK)
- COD_UF – Código de cada UF (PK)
- DES_UF – Descripción de la UF
- NUM_HORAS – Número de horas de la UF
- PONDERA_UF – Ponderación que tiene la UF en la asignatura según sus horas
- TOT_PACS_UF – Total de PACs que tiene la UF
- MIN_PACS_ENT – Mínimo de PACs a entregar para hacer Examen de Ordinaria
- NUM_PACS_ENT – Número de PACs que ha entregado el alumno de esa UF
- NOTA_MEDIA_PACS – Nota media de las PACs entregadas de la UF
- NOTA_EXAM – Nota del examen de la UF
- CONV_EXAM – Convocatoria (ORDINARIA O EXTRAORDINARIA O PROYECTO)

# EJERCICIOS

## EJERCICIO 1) REPASO SQL (TABLAS Y VISTAS)

**1.1.Añadir campos a las tablas ASIGNATURAS y UFS**

 **Tabla ASIGNATURAS**
- Campo NOM_PROFE tipo VARCHAR(50)
- Campo APRO_UFS tipo INT
- Campo NOTA_MEDIA_ASIG tipo NUMBER(4,2)
  
 **Tabla UFS**
- Campo NOTA_MEDIA_UF tipo NUMBER(4,2)
- Campo NOTA_FINAL_UF tipo INT
- Campo STAT_UF tipo VARCHAR(10)

**1.2.Crear una VISTA llamada “EXPEDIENTE”.**
Ha de ser INNER JOIN de las tablas ASIGNATURAS y UFS. Ha de contener los siguientes campos de cada tabla:
**Tabla ASIGNATURAS**
- ABV_ASIG
- DES_ASIG
**Tabla UFS**
- PORC_PACS_ENTRE
  *Campo calculado que será % de PACs Entregadas según el total de PACs de la UF*
- ROUND(num_pacs_ent / tot_pacs_uf * 100,2) AS PORC_PACS_ENTRE
- NOTA_MEDIA_PACS
- NOTA_EXAM
- CONV_EXAM
- NOTA_MEDIA_UF
- NOTA_FINAL_UF
- STAT_UF

**1.3.Actualizar registros de la tabla ASIGNATURAS.**

**Tabla ASIGNATURAS**
Actualizar el campo NOM_PROFE de los registros de las asignaturas de bases de datos:
- COD_ASIG = ICB0102A y COD_ASIG = ICB0102B:
- Nombre del profesor = Emilio Saurina

## EJERCICIO 2) PROCEDIMIENTO
**Crear un procedimiento llamado “P_NOTA_MEDIA_ASIG”**
Crear un procedimiento que a partir de un código asignatura pasado por parámetro nos devuelva el
número de UFS aprobadas y la nota media de la asignatura si estan todas aprobadas
**Variables de entrada**
- VIN_COD_ASIG
**Variables de salida**
- VOUT_APRO_UFS
- VOUT_NOTA_MEDIA_ASIG

Para los cálculos se ha de tener en cuenta lo siguiente:
- Si una UF está aprobada (NOTA_FINAL_UF >= 5):
Se calcula la parte de nota de uf NOTA_FINAL_UF * PONDERA_UF
Se van sumando las notas ponderadas de cada UF

Durante el proceso se han de contar las UFS aprobadas y las NO aprobadas
Se va a devolver el número de UFS aprobadas
- Si hay una o mas UFs NO aprobadas no se puede establecer nota media
El resultado final de NOTA_MEDIA_ASIG = NULL
- Si todas las UFS estan aprobadas
El resultado final es el resultado calculado

## EJERCICIO 3) FUNCION
**Crea una función llamada “F_NOTA_MEDIA_UF”**
Crear una función devuelva la nota media de una UF a partir de los datos siguientes:
Variables de entrada:
- VIN_CONV_EXAM
- VIN_NUM_PACS_ENT
- VIN_MIN_PACS_ENT
- VIN_NOTA_MEDIA_PAC
- VIN_NOTA_EXAM

Para los cálculos se ha de tener en cuenta lo siguiente:
- Si la convocatoria es igual a “EXTRAORDINARIA”:
La nota media es igual a la nota de examen
- Si la convocatoria es “ORDINARIA” tenemos los siguientes casos:
  La nota media es igual a la nota media de pacs por 0,4 en estos casos
  Si el número de pacs entregadas es menor que mínimo de pacs a entregar
  Si la nota de examen es menor a 4,75
  Si la nota media de PACs es menor a 7 y la nota examen entre 4,75 y 4,89 a
  Cuando no se dan ninguno de los demás casos la nota se calcula como
  Nota media es igual a nota media de pacs por 0,4 mas nota examen por 0,6
- Si la convocatoria es “PROYECTO” es un caso peculiar ya que el proyecto no tiene PACS
  La nota media es igual a la nota de examen que es donde se pondrá la nota que tiene
el proyecto

## EJERCICIO 4) TRIGGER
**Crea una trigger llamado “T_ACTUALIZA_NOTA_FINAL”**
• Crear un Trigger que se dispare cuando se actualice la tabla de UFS.
• Usa la función creada para calcular la nota media actualizada de la UF modificada
• Con la nueva NOTA_MEDIA_UF se puede calcular la NOTA_FINAL_UF según la siguiente premisa
o Si la convocatoria nueva es EXTRAORDINARIA
▪ Si la NOTA_MEDIA_UF está entre 4,5 y 4,74
• Coger la parte entera de la NOTA_MEDIA_UF
o Por ejemplo 4,74 → 4

▪ En todos los demás casos se aplica un redondeo normal
• Redondeo normal de la NOTA_MEDIA_UF al alza en 0,5 o mas
o Por ejemplo 4,75 → 5 o 5,49 → 5 o 3,65 → 4

o Si la convocatoria nueva es ORDINARIA
▪ Si la NOTA_MEDIA_UF está entre 4,5 y 4,74
• Coger la parte entera de la NOTA_MEDIA_UF
o Por ejemplo 4,74 → 4

▪ Si la NOTA_MEDIA_UF está entre 4,75 y 4,89 y además la NOTA_MEDIA_PACS < 7
• Coger la parte entera de la NOTA_MEDIA_UF
o Por ejemplo 4,84 con NOTA_MEDIA_PACS = 6 → 4

▪ Si la NOTA_MEDIA_UF está entre 4,75 y 4,89 y además la NOTA_MEDIA_PACS > 7
• Redondeo normal de la NOTA_MEDIA_UF al alza en 0,5 o mas
o Por ejemplo 4,84 con NOTA_MEDIA_PACS = 8 → 5

▪ Si la NOTA_MEDIA_UF es mayor a 4,9
• Redondeo normal de la NOTA_MEDIA_UF al alza en 0,5 o mas
o Por ejemplo 4,94 → 5
o Si la convocatoria nueva es PROYECTO
▪ Si la NOTA_MEDIA_UF entre 4,5 y 4,99 Coger la parte entera
▪ En los demás casos se hace Redondeo Normal
• En el trigger también actualizamos el nuevo valor del campo STAT_UF
o Si la NOTA_FINAL_UF < 5 → SUSPENSO
o Si la NOTA_FINAL_UF >= 5 → APROBADO
o Si la NOTA_FINAL_IF IS NUL → PENDIENTE

## EJERCICIO 5) BLOQUES ANÓNIMOS
**5.1.Crear un bloque anónimo que actualice la NOTA_MEDIA_UF de todas las UFS**
• Usa un cursor con la sentencia FOR UPTADE OF NOTA_MEDIA_UF para recorrer todos los registros de
la tabla UFS y con la ayuda de la función creada F_NOTA_MEDIA_UF se ha de actualizar cada uno de
los registros.
• Si el Trigger está correcto, al modificar la NOTA_MEDIA_UF se han de actualizar los campos
NOTA_FINAL_UF y STAT_UF de forma automática
**5.2.Crear un bloque anónimo que actualice NOTA_MEDIA_ASIG y APRO_UFS de todas las ASIGNATURAS**
• Usa un cursor FOR UPDATE OF APRO_UFS, NOTA_MEDIA_ASIG para recorrer todos los registros de la
tabla ASIGNATURAS y utiliza el procedimiento creado P_NOTA_MEDIA_ASIG para poder actualizar los
valores de cada asignatura.
**5.3.Crear un bloque anónimo que calcule y muestre la nota media final del ciclo**
• Usa un cursor para recorrer todos los registros de la tabla ASIGNATURAS
o Recuerda que se ha de ir multiplicando la NOTA_MEDIA_ASIG por PONDERA_ASIG que es la
ponderación que tiene cada Asignatura en este ciclo
o En caso de que una asignatura no tenga NOTA_MEDIA_ASIG no lo contamos para la media y
la contabilizamos en una variable contador de V_NUM_ASIG_FALTA
o Todas las Notas calculadas se irán sumando en una variable V_NOTA_MEDIA_CICLO
• Al terminar tendremos que sacar un mensaje por pantalla:
o Si no hay asignaturas restantes el mensaje será:
▪ El ciclo se ha terminado con una nota media de: “V_NOTA_MEDIA_CICLO”
o Si tiene asignaturas restantes el mensaje será:
▪ A falta de “V_NUM_ASIG_FALTA” asignaturas por aprobar. La nota media del ciclo es
de: “V_NOTA_MEDIA_CICLO”
