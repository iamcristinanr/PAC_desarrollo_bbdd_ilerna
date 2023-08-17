
---------------------------------------------------------------
-- 1)   REPASO SQL. TABLAS Y VISTAS ------------
---------------------------------------------------------------
--1.1) AÑADIR CAMPOS A LAS TABLAS

-- Tabla ASIGNATURAS
--AGREGA EL CAMPO NOM_PROFE A LA TABLA ASIGNATURALONGITUD MAX 50.
ALTER TABLE ASIGNATURAS ADD NOM_PROFE VARCHAR(50);
ALTER TABLE ASIGNATURAS ADD APRO_UFS INT;
--AGREGA EL CAMPO NOTA_MEDIA_ASIG A LA TABLA ASIGNATURA, TIPO DE DATO NUMERO 4 DIGITOS Y 2 DECIMALES.
ALTER TABLE ASIGNATURAS ADD NOTA_MEDIA_ASIG NUMBER(4,2); 
/
-- Tabla UFS

ALTER TABLE UFS ADD NOTA_MEDIA_UF NUMBER(4,2);
ALTER TABLE UFS ADD NOTA_FINAL_UF INT;
ALTER TABLE UFS ADD STAT_UF VARCHAR(10);
/
--1.2) CREACIÓN DE VISTAS
CREATE OR REPLACE VIEW "EXPEDIENTE" 
AS SELECT a.ABV_ASIG, a.DES_ASIG,
-- CALCULAMOS PORCENTAJE DE PACS ENTREGADAS, EL CAMPO PORC_PACS_ENTRE  REDONDEADO A DOS DECIMALES
ROUND(u.num_pacs_ent / u.tot_pacs_uf * 100,2) AS PORC_PACS_ENTRE, 
u.NOTA_MEDIA_PACS, u.NOTA_EXAM, 
u.CONV_EXAM, u.NOTA_MEDIA_UF, u.NOTA_FINAL_UF, u.STAT_UF
FROM ASIGNATURAS a
INNER JOIN UFS u
ON a.cod_asig=u.cod_asig
/
        
--1.3) ACTUALIZAR REGISTROS

UPDATE ASIGNATURAS  
SET  NOM_PROFE= 'Emilio Saurina'
WHERE COD_ASIG = 'ICB0102A' OR COD_ASIG = 'ICB0102B'
/ 
---------------------------------------------------------------
-- 2)	PROCEDIMIENTOS ----------------------------------
---------------------------------------------------------------
-- CREAR PROCEDIMIENTO "P_NOTA_MEDIA_ASIG"
--CALCULAR LA NOTA MEDIA CADA ASIGNATURA INDICANDO EL CODIGO DE LA ASIGNATURA
CREATE OR REPLACE PROCEDURE p_nota_media_asig (
-- DECLARAMOS VARIABLE DE ENTRADA
    vin_cod_asig         IN VARCHAR2,
-- DECLARAMOS VARIABLES DE SALIDA DEL PROCECIMIENTO
--DEVUELVE LAS UFS APROBADAS Y LA NOTAMEDIA
    vout_apro_ufs        OUT NUMBER,
    vout_nota_media_asig OUT NUMBER
) IS
--DECLARAMOS VARIABLES LOCALES DEL PROCEDIMIENTO PARA REALIZAR CALCULOS Y CONSEGUIR LAS UFS APROBADAS Y LAS QUE NO.

    ufs_aprobadas        NUMBER := 0;
    nota_final_ponderada NUMBER := 0;
    ponderacion_ufs_aprobadas NUMBER := 0;
    ufs_no_aprobadas     NUMBER := 0;
BEGIN   
--RECORRE TODOS LOS REGISTROS DE UFS PARA OBTENER LA NOTA FINAL Y LA PONDERACION TOTAL DE LAS UFS DE CADA ASIGNATURA
    FOR i IN (
        SELECT
            nota_final_uf, pondera_uf
        FROM
            ufs
        WHERE
            cod_asig = vin_cod_asig
    ) LOOP
--COMPROBAR QUE LA NOTA ES MAYOR O IGUAL QUE 5 PARA SACAR LA NOTA FINAL PONDERADA
        IF i.nota_final_uf >= 5 THEN
--CADA UF TIENE DISTINTA PONDERACION SE MULTIPLICA CADA UF POR SU PONDERACION Y LA SUMA LA PONDERACION
            nota_final_ponderada := nota_final_ponderada + ( i.nota_final_uf * i.pondera_uf );
            ponderacion_ufs_aprobadas := ponderacion_ufs_aprobadas + i.pondera_uf;
--CONTADOR UFS APROBADAS
            ufs_aprobadas := ufs_aprobadas + 1; 
--AUNQUE CALCULAMOS SOLO LA NOTA FINAL DE LAS APROBADAS, CONTABILIZAMOS TAMBIEN  LAS NO APROBADAS
        ELSE
--CONTADOR UFS NO APROBADAS
            ufs_no_aprobadas := ufs_no_aprobadas + 1;       
        END IF;
    END LOOP;
    
--ASIGNO A LA VARIABLE DE SALIDA LA VARIABLE DEL PROCEDIMIENTO 

    vout_apro_ufs := ufs_aprobadas;
    BEGIN 

--CONDICION EN FUNCION DE SI APRUEBA O NO LA UFS

    IF  ufs_aprobadas = 0 THEN

--MUESTRA Y EXPLICA EL ERROR-20001 CUANDO NO HAY UFS APROBADAS

    RAISE_APPLICATION_ERROR(-20001, 'No se puede calcular la nota media de una asignatura sin unidades formativas aprobadas.');
--SI HAY UFS NO APROBADAS SE MUESTRA NULL
    ELSIF ufs_no_aprobadas >= 1 THEN
        vout_nota_media_asig := NULL;
    ELSE
--SI TODAS LAS UFS DE LA ASIGNATURA ESTAN APROBADAS CALCULAMPOS EL PROMEDIO PONDERADO PARA SACAR NOTA_MEDIA_ASIG 
        vout_nota_media_asig := nota_final_ponderada / ponderacion_ufs_aprobadas;
    END IF;
 
--SI HAY ERROR SE MUESTRA EL MENSAJE Y SE ASIGNA NULL A LA NOTA MEDIA 
    EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error en el procedimiento p_nota_media_asig: ' || SQLERRM);
                vout_nota_media_asig := NULL;
    END;
END;
/

---------------------------------------------------------------
-- 3)	FUNCIONES ------------------------------------------
---------------------------------------------------------------
-- CREAR FUNCION "F_NOTA_MEDIA_UF"
CREATE OR REPLACE FUNCTION f_nota_media_uf (
--VARIABLES DE ENTRADA
    vin_conv_exam       IN VARCHAR2,
    vin_num_pacs_ent    IN NUMBER,
    vin_min_pacs_ent    IN NUMBER,
    vin_nota_media_pacs IN NUMBER,
    vin_nota_exam       IN NUMBER
) RETURN NUMBER
--  VARIABLE DE SALIDA
 IS
    nota_media_uf NUMBER := 0;
BEGIN
--CONDICIONALES, EN FUNCION DEL ESTADO DE LA CONVOCATORIA (O PROYECTO) LA NOTA SE CALCULA DE UNA FORMA DISTINTA
    IF vin_conv_exam = 'EXTRAORDINARIA' THEN
        nota_media_uf := vin_nota_exam;
    ELSIF vin_conv_exam = 'ORDINARIA' THEN
--SI ES ORDINARIA TAMBIEN SE TIENE QUE TENER EN CUENTA SI SE HAN ENTREGADO LAS PACS MINIMAS
--SI EL NUMERO DE PACS ENTREGADAS ES INFERIOR AL MINIMO DE PACS ENTREGADAS SE EJECUTARA LO SIGUIENTE:
        IF vin_num_pacs_ent < vin_min_pacs_ent OR vin_nota_exam < 4.75 OR vin_nota_media_pacs < 7
        AND vin_nota_exam BETWEEN 4.75 AND 4.89 THEN
            nota_media_uf := vin_nota_media_pacs * 0.4;
--EN CASO DE NO HABER ENTREGADO LAS PACS MINIMAS:
        ELSE
            nota_media_uf := vin_nota_media_pacs * 0.4 + vin_nota_exam * 0.6;
        END IF;
    ELSIF vin_conv_exam = 'PROYECTO' THEN
        nota_media_uf := vin_nota_exam;
    END IF;

    RETURN nota_media_uf;
END;
/
---------------------------------------------------------------
-- 4)	TRIGGERS ---------------------------------------------
---------------------------------------------------------------
-- CREAR TRIGGER "T_ACTUALIZA_NOTA_FINAL"

--TRIGGER PARA QUE AL ACTUALIZAR LA NOTA MEDIA SE ACTUALIZEN LOS CAMPOS NOTA FINAL UF Y ESTATUS UF
--nota_final_uf
--stat_uf

--BEFORE, SE ACTIVA ANTES DE LA ACTUALIZACION DE NOTA_MEDIA_UF EN UFS PARA CADA FILA
--COMPROBAMOS QUE SE PUEDE CALCULAR LA NOTA_MEDIA_UF PARA DESPUES ACTUALIZAR LOS CAMPOS NOTA_FINA_UF Y STAT_UF

CREATE OR REPLACE TRIGGER t_actualiza_nota_final BEFORE
    UPDATE OF nota_media_uf ON ufs
    FOR EACH ROW

DECLARE
    nota_media_uf ufs.nota_media_uf%TYPE;
    nota_final_uf ufs.nota_final_uf%TYPE;

--CALCULAR LA NOTA FINAL DE LA UF EN FUNCION DE LA CONVOCATORIA
--EN FUNCION DE CADA TIPO DE CONVOCATORIA O SI ES PROYECTO Y NOTA DEBE REDONDEAR DE UNA MANERA U OTRA
--TRUNC, ELIMINA LOS DECIMALES
--ROUND,  REDONDEA AL MAS CERCANO, EJ. De 5,3 pasa a 5, pero de 5,7 pasa a 6.

BEGIN

    CASE :new.conv_exam
        WHEN 'EXTRAORDINARIA' THEN
            IF :new.nota_media_uf BETWEEN 4.5 AND 4.74 THEN
                :new.nota_final_uf := trunc(:new.nota_media_uf);
            ELSE
                :new.nota_final_uf := round(:new.nota_media_uf);
            END IF;
        WHEN 'ORDINARIA' THEN
            IF :new.nota_media_uf BETWEEN 4.5 AND 4.74 THEN
                :new.nota_final_uf := trunc(:new.nota_media_uf);
            ELSIF
                :new.nota_media_uf BETWEEN 4.75 AND 4.89
                AND :new.nota_media_pacs < 7
            THEN
                :new.nota_final_uf := trunc(:new.nota_media_uf);
            ELSIF
                :new.nota_media_uf BETWEEN 4.75 AND 4.89
                AND :new.nota_media_pacs >= 7
            THEN
                :new.nota_final_uf := round(:new.nota_media_uf);
            ELSE
                :new.nota_final_uf := round(:new.nota_media_uf);
            END IF;
        WHEN 'PROYECTO' THEN
            IF :new.nota_media_uf BETWEEN 4.5 AND 4.99 THEN
                :new.nota_final_uf := trunc(:new.nota_media_uf);
            ELSE
                :new.nota_final_uf := round(:new.nota_media_uf);
            END IF;
        ELSE
            :new.nota_final_uf := NULL;
    END CASE;

--ACTUALIZAR EL VALOR DEL CAMPO STAT_UF EN FUNCION DE LA NOTA FINAL DE LA UF
--STAT_UF SERÁ "PENDIENTE" SI NOTA_FINAL_UF ES NULL
--SERÁ "SUSPENSO" SI NOTA_FINAL_UF ES < 5

    IF :new.nota_final_uf IS NULL THEN
        :new.stat_uf := 'PENDIENTE';
    ELSIF :new.nota_final_uf < 5 THEN
        :new.stat_uf := 'SUSPENSO';
    ELSE
        :new.stat_uf := 'APROBADO';
    END IF;

END;
/
---------------------------------------------------------------
-- 5)   BLOQUES ANÓNIMOS  ----------------------------
---------------------------------------------------------------

--5.1) Actualizar las nota media de todas las UFs
DECLARE

-- CURSOR QUE APUNTA A TODOS LOS REGISTROS DE UFS PARA ACTUALIZAR nota_media_uf

    CURSOR c_ufs IS
    SELECT
        *
    FROM
        ufs
--BLOQUEAMOS LA FILA PARA AÑADIR LA ACTUALIZACION.
    FOR UPDATE OF nota_media_uf; 

--UTILIZAMOS LA FUNCION f_nota_media_uf Y LE PASAMOS LOS PARAMETROS NECESARIOS RECOGIDOS POR EL CURSOR.

BEGIN

--R.UF CADA FILA DEL CURSOR
--POR CADA FILA ACTUALIZAMOS nota_media_uf CON FUNCION f_nota_media_uf

    FOR r_uf IN c_ufs LOOP
        UPDATE ufs
        SET
            nota_media_uf = f_nota_media_uf(r_uf.conv_exam, r_uf.num_pacs_ent, r_uf.min_pacs_ent, r_uf.nota_media_pacs, r_uf.nota_exam
            )
        WHERE
-- HACEMOS REFERENTE AL REGISTRO ACTUAL DEL CURSOR
            CURRENT OF c_ufs;

    END LOOP;
END;
/
--5.2) Actualizar las nota media de todas las asignaturas

DECLARE

--CURSOR QUE RECORRE TODOS LOS REGISTROS DE TABLA ASIGNATURAS PARA ACTUALIZAR  apro_ufs y nota_media_asig
    CURSOR c_asignaturas IS
    SELECT
        *
    FROM
        asignaturas
    FOR UPDATE OF apro_ufs,
                  nota_media_asig;

    v_apro_ufs asignaturas.apro_ufs%TYPE;
    v_nota_media_asig asignaturas.nota_media_asig%TYPE;

-- RECORRE TODAS LAS FILAS DEL CURSOR Y ACTUALIZA LLAMANDO AL PROCEDIMIENTO p_nota_media_asig y pasandole los valores necesarios para la ejecucion
--del procedimiento.

BEGIN
    FOR r_asig IN c_asignaturas LOOP
        p_nota_media_asig(r_asig.cod_asig, v_apro_ufs, v_nota_media_asig);
        UPDATE asignaturas
        SET
            apro_ufs = v_apro_ufs,
            nota_media_asig = v_nota_media_asig
        WHERE
            CURRENT OF c_asignaturas;
    END LOOP;
END;

/
--5.3) Crear un bloque anónimo que calcule la nota media final del ciclo

-- PARA LA SALIDA DE MENSAJES POR PANTALLA

SET SERVEROUTPUT ON
 
-- CURSOR QUE RECORRE TODOS LOS REGISTROS DE LA TABLA ASIGNATURAS
 DECLARE   
    CURSOR c_asignaturas IS
    SELECT
	*
    FROM
        asignaturas;
        
 V_NOTA_MEDIA_CICLO NUMBER := 0;
 V_NUM_ASIG_FALTA NUMBER :=0;
    v_nota_media_asig asignaturas.nota_media_asig%TYPE;
    v_pondera_asig asignaturas.pondera_asig%TYPE;
 
BEGIN
--RECORREMOS TODAS LAS ASIGNATURAS PARA OBNETER LA NOTA MEDIA Y LA PONDERACION
    FOR r_asig IN c_asignaturas LOOP
        v_nota_media_asig := r_asig.nota_media_asig;
        v_pondera_asig := r_asig.pondera_asig;
--CONDICIONALES PARA CALCULAR LA NOTA MEDIA DEL CICLO
--SI ESTA APROBADA SE CALCULA LA NOTA MEDIA           
        IF v_nota_media_asig IS NOT NULL THEN
            v_nota_media_ciclo := v_nota_media_ciclo + ( v_nota_media_asig * v_pondera_asig );  
-- SI NO ESTA APROBADA SE SUMA AL CONTADOR DE LAS ASIGNATURAS NO APROBADAS
        ELSE
            v_num_asig_falta := v_num_asig_falta + 1;
        END IF;

    END LOOP;
--SI TODAS LAS ASIGNATURAS ESTAN APROBADAS SE MOSTRARÁ:
    IF v_num_asig_falta = 0 THEN
        dbms_output.put_line('El ciclo se ha terminado con una nota media de: ' || v_nota_media_ciclo);
-- SI HAY ASIGNATURAS PENDIENTES:
    ELSE
        dbms_output.put_line('A falta de '
                             || v_num_asig_falta
                             || ' asignaturas por aprobar. La nota media del ciclo es de: '
                             || v_nota_media_ciclo);
    END IF;

END;
/
/* COMENTAR QUE SEGUN LA PAC REALIZO CURSORES QUE APUNTAN A TODOS LOS REGISTROS SIN EMBARGO PODRIAMOS UTILIZAR PARA MAYOR OPTIMIZACION SOLO 
LOS NECESARIOS EJ. EJERCICIO 5.3.
 CURSOR QUE RECORRE TODOS LOS REGISTROS
 DECLARE   
    CURSOR c_asignaturas IS
    SELECT
        pondera_asig,
        nota_media_asig
    FROM
        asignaturas
*/


