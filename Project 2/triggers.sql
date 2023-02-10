-- To add a log entry when a student is registered
CREATE OR REPLACE TRIGGER ADD_STUDENT
  AFTER INSERT
  ON STUDENTS
  FOR EACH ROW
DECLARE
  keyValue LOGS.TUPLE_KEYVALUE%TYPE;
BEGIN
  keyValue := :new.B#;
  INSERT INTO LOGS (LOG#, USER_NAME, OP_TIME, TABLE_NAME, OPERATION, TUPLE_KEYVALUE)
    VALUES (log_sequence.NEXTVAL, user, SYSDATE, 'Students', 'Insert', keyvalue);
END;
/


-- To deleted all the student enrollments and add a log entry when a student is deleted
CREATE OR REPLACE TRIGGER DELETE_STUDENT
  AFTER DELETE 
  ON STUDENTS
  FOR EACH ROW
DECLARE
  keyValue LOGS.TUPLE_KEYVALUE%TYPE;
BEGIN
    DELETE FROM G_ENROLLMENTS WHERE G_B# = :old.B#;									
    keyValue := :old.B#;
  INSERT INTO LOGS (LOG#, USER_NAME, OP_TIME, TABLE_NAME, OPERATION, TUPLE_KEYVALUE)
    VALUES (log_sequence.NEXTVAL, user, SYSDATE, 'Students', 'Delete', keyValue);
END;
/


-- To add a log entry when a student is enrolled in a class
CREATE OR REPLACE TRIGGER ADD_ENROLLMENT
  AFTER INSERT
  ON G_ENROLLMENTS
  FOR EACH ROW
DECLARE
  keyValue LOGS.TUPLE_KEYVALUE%TYPE;
BEGIN
  keyValue := :new.G_B# || ',' || :new.classid;
  INSERT INTO LOGS (LOG#, USER_NAME, OP_TIME, TABLE_NAME, OPERATION, TUPLE_KEYVALUE)
    VALUES (log_sequence.NEXTVAL, user, SYSDATE, 'G_Enrollments', 'Insert', keyValue);
END;
/


-- To add a log entry when a student is removed from a class
CREATE OR REPLACE TRIGGER DELETE_ENROLLMENT
  AFTER DELETE 
  ON G_ENROLLMENTS
  FOR EACH ROW
DECLARE
  keyValue LOGS.TUPLE_KEYVALUE%TYPE;
BEGIN
    keyValue := :old.G_B# || ',' || :old.classid;
  INSERT INTO LOGS (LOG#, USER_NAME, OP_TIME, TABLE_NAME, OPERATION, TUPLE_KEYVALUE)
    VALUES (log_sequence.NEXTVAL, user, SYSDATE, 'G_Enrollments', 'Delete', keyValue);
END;
/


-- To increase class size of a class in classes table when a new student is enrolled in that class
CREATE OR REPLACE TRIGGER INCREASE_CLASS_SIZE
  BEFORE INSERT ON G_ENROLLMENTS
  FOR EACH ROW
  DECLARE
    oldClassSize CLASSES.CLASS_SIZE%TYPE;
    classLimit CLASSES.LIMIT%TYPE;
    classIsFull EXCEPTION;
  BEGIN
  SELECT class_size, LIMIT INTO oldClassSize, classLimit FROM CLASSES WHERE classid = :new.classid;
  IF (oldClassSize = classLimit) THEN
    raise classIsFull;
  ELSE
    UPDATE CLASSES SET class_size = oldClassSize + 1 WHERE classid = :new.classid;
  END IF;
  EXCEPTION 
  WHEN classIsFull 
  THEN RAISE_APPLICATION_ERROR(-20000, 'The class is full.');		
END;
/


--To decrease class size of a class in classes table when a student is removed from the class
CREATE OR REPLACE TRIGGER DECREASE_CLASS_SIZE 
  AFTER DELETE ON G_ENROLLMENTS FOR EACH ROW 
  DECLARE 
    oldClassSize CLASSES.CLASS_SIZE%TYPE;
  BEGIN
  SELECT class_size INTO oldClassSize FROM CLASSES WHERE classid = :old.classid;
  UPDATE CLASSES SET class_size = oldClassSize - 1 WHERE classid  = :old.classid;
END;
/

show errors;