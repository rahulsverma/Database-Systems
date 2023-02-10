CREATE OR REPLACE PACKAGE student_operations
AS
	PROCEDURE showTuples (
    tableName IN VARCHAR2,
    refCursor OUT sys_refcursor );
	
	PROCEDURE showClassDetails (
    Class#  IN CLASSES.classid%type,
    refCursor OUT sys_refcursor);
		
	PROCEDURE listPrerequisites(
    DeptCode IN PREREQUISITES.pre_dept_code%TYPE,
    Courseid   IN PREREQUISITES.pre_course#%TYPE,
    refCursor OUT sys_refcursor);
	  
	PROCEDURE enrollStudent(
    B#     IN STUDENTS.B#%TYPE,
    Class# IN CLASSES.classid%TYPE,
gpa IN score_grade.score%TYPE);
	  
	PROCEDURE deleteStudentEnrollment(
    B#     IN G_ENROLLMENTS.G_B#%TYPE,
    Class# IN G_ENROLLMENTS.classid%TYPE);
	  
	PROCEDURE deleteStudent(
    B# IN STUDENTS.B#%TYPE);

PROCEDURE enrollStudent1(
    B#     IN VARCHAR2,
    Class# IN VARCHAR2,
    gpa IN FLOAT);
	  
END student_operations;
/

CREATE OR REPLACE PACKAGE BODY student_operations
AS

-- Returns a count greater than 0 if a class is present in the CLASSES table
FUNCTION isClassAvailable(
    Class# IN CLASSES.classid%TYPE)
  RETURN INTEGER
  IS
    classCount INTEGER;
  BEGIN
    SELECT COUNT(*) INTO classCount FROM CLASSES WHERE classid = Class#;
    RETURN (classCount);
  END;

-- Returns a count greater than 0 if a student is registered in the STUDENTS table
FUNCTION isStudentRegistered(
      B# IN STUDENTS.B#%type)
    RETURN INTEGER
  IS
    studentCount INTEGER;
  BEGIN
    SELECT COUNT(*) INTO studentCount FROM STUDENTS st WHERE st.B# = B#;
    RETURN (studentCount);
  END;

-- Returns a count greater than 0 if a student is enrolled in a class in the G_ENROLLMENTS table
FUNCTION isStudentEnrolled(
      B#     IN STUDENTS.B#%type,
      Class# IN CLASSES.classid%TYPE)
    RETURN INTEGER
  IS
    enrollmentCount INTEGER;
  BEGIN
    SELECT COUNT(*) INTO enrollmentCount FROM G_ENROLLMENTS WHERE classid = Class# AND G_B# = B#;	
    RETURN (enrollmentCount);
  END;

-- To display all the tuples based on the given table name
PROCEDURE showTuples (
    tableName IN VARCHAR2,
    refCursor OUT sys_refcursor )
  IS 
  BEGIN
    CASE tableName
    WHEN 'STUDENTS' THEN
      OPEN refCursor FOR SELECT * FROM STUDENTS;
    WHEN 'COURSES' THEN
      OPEN refCursor FOR SELECT * FROM COURSES;
    WHEN 'COURSE_CREDIT' THEN
      OPEN refCursor FOR SELECT * FROM COURSE_CREDIT;
    WHEN 'CLASSES' THEN
      OPEN refCursor FOR SELECT * FROM CLASSES;
    WHEN 'G_ENROLLMENTS' THEN
      OPEN refCursor FOR SELECT * FROM G_ENROLLMENTS;
    WHEN 'SCORE_GRADE' THEN
      OPEN refCursor FOR SELECT * FROM SCORE_GRADE;
    WHEN 'PREREQUISITES' THEN
      OPEN refCursor FOR SELECT * FROM PREREQUISITES;
    WHEN 'LOGS' THEN
      OPEN refCursor FOR SELECT * FROM LOGS;
    END CASE;
  END showTuples;
  
-- To show all the students in a class with respect to the classid
PROCEDURE showClassDetails (
    Class# in Classes.classid%type,
    refCursor OUT sys_refcursor)
  IS
  classInvalidException EXCEPTION;
  BEGIN
  IF (isClassAvailable(Class#) <> 1) THEN
      raise classInvalidException;
  END IF;
    open refCursor
    FOR
    SELECT st.B#, st.first_name, st.last_name FROM G_ENROLLMENTS ge join STUDENTS st on ge.G_B# = st.B#	join CLASSES cl on cl.classid = ge.classid and cl.classid = Class#;   
    EXCEPTION
  WHEN classInvalidException THEN
    RAISE_APPLICATION_ERROR(-20000, 'The classid is invalid');
  END showClassDetails;
  
-- To show prerequisites of a given course based in the courseid
PROCEDURE listPrerequisites(
      DeptCode IN PREREQUISITES.pre_dept_code%TYPE,
      Courseid   IN PREREQUISITES.pre_course#%TYPE,
      refCursor OUT sys_refcursor)
  IS
  courseDoesntExistException EXCEPTION;
  BEGIN
    OPEN refCursor FOR SELECT (pre_dept_code || pre_course#) as courses FROM PREREQUISITES START WITH dept_code=DeptCode AND course#=Courseid CONNECT BY PRIOR pre_dept_code = dept_code AND PRIOR pre_course# = course#;
	EXCEPTION
  WHEN courseDoesntExistException THEN
    RAISE_APPLICATION_ERROR(-20000, 'dept_code || course# does not exist');
  END listPrerequisites;

-- To enroll student into a class
PROCEDURE enrollStudent(
    B#     IN STUDENTS.B#%TYPE,
    Class# IN CLASSES.classid%TYPE,
gpa IN score_grade.score%TYPE)
  IS
    tupleCount                           NUMBER(1);
    limitValue					                 NUMBER(1);
	  sizeValue					                   NUMBER(1);
	  exceedingClassLimitException		     EXCEPTION;
	  invalidUserException                 EXCEPTION;
    invalidClassException                EXCEPTION;
	  notAGraduateStudentException			   EXCEPTION;
	  currentSemesterException	 EXCEPTION;
    duplicateEnrollmentException         EXCEPTION;
    classLimitExceededException          EXCEPTION;
    prerequirementException              EXCEPTION;
  BEGIN
    SELECT COUNT(*) INTO tupleCount FROM STUDENTS s WHERE s.B# = B#;
    IF tupleCount = 0 THEN
      RAISE invalidUserException;
    END IF;
	  SELECT COUNT(*) INTO tupleCount FROM STUDENTS s WHERE s.st_level in ('master','PhD') and s.B# = B#;
    IF tupleCount = 0 THEN
      RAISE notAGraduateStudentException;
    END IF;
    SELECT COUNT(*) INTO tupleCount FROM CLASSES c WHERE c.classid = Class#;
    IF tupleCount = 0 THEN
      RAISE invalidClassException;
    END IF;
	  SELECT c.limit INTO limitValue FROM CLASSES c WHERE c.classid = Class#;
    SELECT c.class_size INTO sizeValue FROM CLASSES c WHERE c.classid = Class#;
    IF limitValue = sizeValue THEN
      RAISE exceedingClassLimitException;
    END IF;
	  SELECT COUNT(*) INTO tupleCount FROM CLASSES c WHERE c.semester = 'Spring' and c.year = 2021 and c.classid = Class#;
    IF tupleCount = 0 THEN
      RAISE currentSemesterException;
    END IF;
    SELECT COUNT(*) INTO tupleCount FROM G_ENROLLMENTS ge WHERE ge.G_B# = B# AND ge.classid = Class#;
    IF tupleCount = 1 THEN
      RAISE duplicateEnrollmentException;
    END IF;
    SELECT COUNT(*) INTO tupleCount FROM G_ENROLLMENTS ge join CLASSES c on ge.classid = c.classid AND ge.G_B# = B#
    AND c.classid IN
      (SELECT classid
      FROM CLASSES
      WHERE (semester, YEAR) =
        (SELECT semester, YEAR FROM CLASSES WHERE classid = Class#
        )
      );
    IF tupleCount = 5 THEN
      RAISE classLimitExceededException;
    END IF;
    SELECT COUNT(*) INTO tupleCount FROM G_ENROLLMENTS ge join score_grade sg on ge.score = sg.score and ge.G_B# = B#
    AND classid IN
      (SELECT classid
      FROM CLASSES c
      WHERE (dept_code, course#) IN
        (SELECT pre_dept_code,
          pre_course#
        FROM PREREQUISITES
        WHERE (dept_code, course#) =
          (SELECT dept_code, course# FROM CLASSES WHERE classid = Class#)
        )
      )
    AND sg.lgrade IN ('C-', 'D', 'F', 'I');													
    IF tupleCount > 0 THEN
      RAISE prerequirementException;
    END IF;
    INSERT INTO G_ENROLLMENTS VALUES (B#, Class#, gpa);
  EXCEPTION
  WHEN invalidUserException THEN
    RAISE_APPLICATION_ERROR(-20001, 'The B# is invalid.');
  WHEN invalidClassException THEN
    RAISE_APPLICATION_ERROR(-20002, 'The classid is invalid.');
  WHEN duplicateEnrollmentException THEN
    RAISE_APPLICATION_ERROR(-20003, 'The student is already in the class.');
  WHEN classLimitExceededException THEN
    RAISE_APPLICATION_ERROR(-20004, 'Students cannot be enrolled in more than five classes in the semester.');
  WHEN notAGraduateStudentException THEN
    RAISE_APPLICATION_ERROR(-20005, 'This is not a graduate student.');
  WHEN currentSemesterException THEN
    RAISE_APPLICATION_ERROR(-20006, 'Cannot enroll into a class from a previous semester.');
  WHEN exceedingClassLimitException THEN
    RAISE_APPLICATION_ERROR(-20007, 'The class is already full.');
  WHEN prerequirementException THEN
    RAISE_APPLICATION_ERROR(-20008, 'Prerequisite not satisfied.');
  END enrollStudent;

-- To delete enrolment of a student in a class :

PROCEDURE deleteStudentEnrollment(
    B#      IN G_ENROLLMENTS.G_B#%TYPE,
    Class#  IN G_ENROLLMENTS.classid%TYPE)
  IS
    tupleCount                             NUMBER(1);
    classNotAvailableException             EXCEPTION;
    studentNotRegisteredException          EXCEPTION;
    studentNotEnrolledException            EXCEPTION;
	  notAGraduateStudentException			     EXCEPTION;
	  currentSemesterException		 EXCEPTION;
	  lastClassException	                   EXCEPTION;
  BEGIN
    IF (isClassAvailable(Class#) <> 1) THEN
      raise classNotAvailableException;
    END IF;
	SELECT COUNT(*) INTO tupleCount FROM G_ENROLLMENTS ge join CLASSES cl on ge.classid = cl.classid and cl.semester = 'Spring' and cl.year = 2021 and ge.G_B# = B#;
    IF (tupleCount = 1) THEN
      raise lastClassException;    					
    END IF;
    IF (isStudentRegistered(B#) <> 1) THEN
      raise studentNotRegisteredException;
     END IF;
    IF (isStudentEnrolled(Class#, B#) = 0) THEN
      raise studentNotEnrolledException;
    END IF;
	SELECT COUNT(*) INTO tupleCount FROM STUDENTS s WHERE s.st_level in ('master','PhD') and s.B# = B#;
    IF tupleCount = 0 THEN
      RAISE notAGraduateStudentException;
    END IF;
	SELECT COUNT(*) INTO tupleCount FROM CLASSES c WHERE c.semester = 'Spring' and c.year = 2021 and c.CLASSID = Class#;
    IF tupleCount = 0 THEN
      RAISE currentSemesterException;
    END IF;
    DELETE FROM G_ENROLLMENTS WHERE classid = Class# AND G_B# = B#;
  EXCEPTION
  WHEN classNotAvailableException THEN
    RAISE_APPLICATION_ERROR(-20001, 'The classid is invalid.');
  WHEN studentNotRegisteredException THEN
    RAISE_APPLICATION_ERROR(-20002, 'The B# is invalid.');
  WHEN studentNotEnrolledException THEN
    RAISE_APPLICATION_ERROR(-20003, 'The student is not enrolled in the class.');
  WHEN notAGraduateStudentException THEN
    RAISE_APPLICATION_ERROR(-20004, 'This is not a graduate student.');
  WHEN currentSemesterException THEN
    RAISE_APPLICATION_ERROR(-20005, 'Only enrollment in the current semester can be dropped');
  WHEN lastClassException THEN
    RAISE_APPLICATION_ERROR(-20006, 'This is the only class for this student in Spring 2021 and cannot be dropped.');
  END deleteStudentEnrollment;

--To delete student entry
PROCEDURE deleteStudent(
    B# IN STUDENTS.B#%TYPE)
  IS
    studentNotRegisteredException  EXCEPTION;
  BEGIN
  delete from G_ENROLLMENTS where G_B# = B#;
  delete from STUDENTS st where st.B# = B#;
  END deleteStudent;

PROCEDURE enrollStudent1(
    B#     IN VARCHAR2,
    Class# IN VARCHAR2,
    gpa IN FLOAT)
  IS 
tupleCount                           NUMBER(1);
    limitValue                                                   NUMBER(1);
          sizeValue                                                        NUMBER(1);
          exceedingClassLimitException               EXCEPTION;
          invalidUserException                 EXCEPTION;
    invalidClassException                EXCEPTION;
          notAGraduateStudentException                     EXCEPTION;
          currentSemesterException	 EXCEPTION;
    duplicateEnrollmentException         EXCEPTION;
    classLimitExceededException          EXCEPTION;
    prerequirementException              EXCEPTION;


  BEGIN
    INSERT INTO G_ENROLLMENTS VALUES (B#, Class#, gpa);
EXCEPTION
  WHEN invalidUserException THEN
    RAISE_APPLICATION_ERROR(-20001, 'The B# is invalid.');
  WHEN invalidClassException THEN
    RAISE_APPLICATION_ERROR(-20002, 'The classid is invalid.');
  WHEN duplicateEnrollmentException THEN
    RAISE_APPLICATION_ERROR(-20003, 'The student is already in the class.');
  WHEN classLimitExceededException THEN
    RAISE_APPLICATION_ERROR(-20004, 'Students cannot be enrolled in more than five classes in the semester.');
  WHEN notAGraduateStudentException THEN
    RAISE_APPLICATION_ERROR(-20005, 'This is not a graduate student.');
  WHEN currentSemesterException THEN
    RAISE_APPLICATION_ERROR(-20006, 'Cannot enroll into a class from a previous semester.');
  WHEN exceedingClassLimitException THEN
    RAISE_APPLICATION_ERROR(-20007, 'The class is already full.');
  WHEN prerequirementException THEN
    RAISE_APPLICATION_ERROR(-20008, 'Prerequisite not satisfied.');
  
END enrollStudent1;



END student_operations;
/
