set verify off;
set serveroutput on; 

--Generar un paquete de PKG_JOBS. 
--En su interior debe estar conformado por estos componentes.

CREATE OR REPLACE PACKAGE PKG_JOBS AS 
PROCEDURE Alta_Job(IdJob IN VARCHAR, Nombre IN VARCHAR, SalarioMinimo IN NUMBER, SalarioMaximo IN NUMBER);
PROCEDURE Upd_Job(IdJob IN VARCHAR, SalarioMinimo IN NUMBER, SalarioMaximo IN NUMBER);
PROCEDURE Lista_job(IdJob IN VARCHAR);
END PACKAGE;

CREATE OR REPLACE PACKAGE BODY PKG_JOBS AS

--Un procedimiento Alta_Job para insertar un nuevo cargo en la tabla JOBS: 
    --a. Se deben pasar todos los parametros necesarios para completar el registro de la tabla.
    --b. El nombre del cargo debe estár en mayúsculas.
    --c. El codigo del cargo no puede repetirse. En ese caso, tratarlo con la excepción DUP_VAL_ON_INDEX.
    
PROCEDURE Alta_Job (IdJob IN VARCHAR, Nombre IN VARCHAR, SalarioMinimo IN NUMBER, SalarioMaximo IN NUMBER)
 IS 
 BEGIN
 
    INSERT INTO JOBS (job_id,job_title, min_salary, max_salary)
    VALUES (IdJob, Upper(Nombre), SalarioMinimo, SalarioMaximo);

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN 
        DBMS_OUTPUT.PUT_LINE('No se puede duplicar el nombre del cargo: ' || IdJob);
    END;

--Un procedimiento Upd_Job para actualizar los salarios minimos y maximos de los cargos:
    --a. Informar el job_id y nuevo salario minimo y maximo.
    --b. Si el job_id no existe, informar mediante un mensaje y cancelar el procedimiento.
    --c. Debera validarse que el salario maximo sea mayor al minimo.
    
PROCEDURE Upd_Job (IdJob IN VARCHAR, SalarioMinimo IN NUMBER, SalarioMaximo IN NUMBER)
 IS 
  EXCEPCION EXCEPTION;
  EXCEPCION2 EXCEPTION;
 BEGIN

    IF (SalarioMaximo > SalarioMinimo) THEN 
        UPDATE JOBS SET MIN_SALARY = SalarioMinimo,MAX_SALARY = SalarioMaximo
        WHERE JOB_ID =IdJob;
    ELSE
        RAISE EXCEPCION2;
    END IF;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE EXCEPCION;
    ELSE
        DBMS_OUTPUT.PUT_LINE('JOB_ID: ' || IdJob || ' ' || 'Salario minimo: ' || SalarioMinimo || 
        ' ' || 'SalarioMaximo: ' || SalarioMaximo);
    END IF;
 
    EXCEPTION
        WHEN EXCEPCION THEN 
        DBMS_OUTPUT.PUT_LINE('No existe el JOB_ID: ' || IdJob);
        WHEN EXCEPCION2 THEN 
        DBMS_OUTPUT.PUT_LINE('El salario minimo no puedo ser mayor al salario maximo');
 END;    

--Un procedimiento Lista_job que recibe mediante un parámetro el código de un cargo
--e informe el nombre y apellido de todos los empleados que lo poseen. 
    --Contemplar todos los siguientes errores posibles.
    --El código no corresponde a un cargo.
    --No hay empleados en el cargo

PROCEDURE Lista_job (IdJob IN VARCHAR)
 IS 
   EXCEPCION EXCEPTION;
   Nombre employees.first_name%type;
   Contador integer :=0;
  CURSOR C1 IS
    SELECT first_name || ' ' || last_name
           INTO Nombre
            FROM EMPLOYEES WHERE EMPLOYEES.JOB_ID = IdJOB;
            
 BEGIN
    
    SELECT 1 FIRST_NAME INTO Nombre FROM EMPLOYEES WHERE EMPLOYEES.JOB_ID = IdJOB;

    SELECT COUNT (EMPLOYEE_ID) INTO Contador
    FROM EMPLOYEES WHERE EMPLOYEES.JOB_ID = IdJOB;

    IF Contador = 0 THEN
        RAISE EXCEPCION;
    ELSE
        OPEN C1;
            LOOP
                FETCH C1 INTO Nombre;
                EXIT WHEN C1%NOTFOUND;
                dbms_output.Put_line('JOB_ID: ' || IdJob || ' ' ||'Nombre: '|| Nombre); 
            END LOOP;
        CLOSE C1;    
    END IF;
 
    EXCEPTION
        when no_data_found then
        dbms_output.put_line('El IdJob: ' || IdJob || ' no existe');
        when EXCEPCION then
        dbms_output.put_line('No hay empleados en el cargo'); 
END;    

END PKG_JOBS;

--2. Generar un trigger llamado valida_emp_job_sal que realice una validacion por la cual,
--cuando se de el alta a un nuevo empleado, su salario debera estar en el rango permitido
--por el maximo y minimo definido para el cargo.

CREATE OR REPLACE TRIGGER valida_emp_job_sal
BEFORE INSERT on EMPLOYEES 
FOR EACH ROW
DECLARE
    SalarioMax JOBS.MAX_SALARY%TYPE;
    SalarioMin JOBS.MIN_SALARY%TYPE;
    Titulo JOBS.JOB_TITLE%TYPE;
    EXCEPCION EXCEPTION;
BEGIN
    SELECT 1 JOB_TITLE INTO Titulo FROM JOBS WHERE JOB_ID = :new.JOB_ID;
    SELECT MIN_SALARY,MAX_SALARY INTO SalarioMin,SalarioMax FROM JOBS WHERE JOB_ID = :new.JOB_ID;
    IF(:new.SALARY < SalarioMin OR :new.SALARY > SalarioMax) THEN
        RAISE EXCEPCION;
    END IF;
    EXCEPTION
        when EXCEPCION then
        RAISE_APPLICATION_ERROR(-20000,'El salario no se encuentra en el rango del JOB_ID: '|| :new.JOB_ID);
        when no_data_found then
        RAISE_APPLICATION_ERROR(-20000,'El IdJob: ' || :new.JOB_ID || ' no existe');
 END;
 

