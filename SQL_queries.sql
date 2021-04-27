/*
CREATE TABLE points_system (
    event  VARCHAR2(18) NOT NULL,
    a      NUMBER(8, 5) NOT NULL,
    b      NUMBER(8, 5) NOT NULL,
    c      NUMBER(8, 5) NOT NULL,
    unit   VARCHAR2(7) NOT NULL CHECK ( unit IN ( 'seconds', 'metres' ) )
);

ALTER TABLE points_system ADD CONSTRAINT event_pk PRIMARY KEY ( event );

INSERT ALL 
INTO points_system ( event, a, b, c, unit ) VALUES ( '100 m', 25.4347, 18, 1.81, 'seconds' )
INTO points_system ( event, a, b, c, unit ) VALUES ( 'Long jump', 0.14354, 220, 1.4, 'metres' )
INTO points_system ( event, a, b, c, unit ) VALUES ( 'Shot put', 51.39, 1.5, 1.05, 'metres' )
INTO points_system ( event, a, b, c, unit ) VALUES ( 'High jump', 0.8465, 75, 1.42, 'metres' )
INTO points_system ( event, a, b, c, unit ) VALUES ( '400 m', 1.53775, 82, 1.81, 'seconds' )
INTO points_system ( event, a, b, c, unit ) VALUES ( '110 m hurdles', 5.74352, 28.5, 1.92, 'seconds' )
INTO points_system ( event, a, b, c, unit ) VALUES ( 'Discus throw', 12.91, 4, 1.1, 'metres' )
INTO points_system ( event, a, b, c, unit ) VALUES ( 'Pole vault', 0.2797, 100, 1.35, 'metres' )
INTO points_system ( event, a, b, c, unit ) VALUES ( 'Javelin throw', 10.14, 7, 1.08, 'metres' )
INTO points_system ( event, a, b, c, unit ) VALUES ( '1500 m', 0.03768, 480, 1.85, 'seconds' )
SELECT * FROM dual;

COMMIT;
*/

--DROP TABLE points_system;

--SELECT * FROM points_system;

/*
CREATE TABLE error_log (
    module_owner  VARCHAR(30),
    module_name   VARCHAR(30),
    error_line    INTEGER,
    module_user   VARCHAR2(30),
    created_on    TIMESTAMP,
    code          NUMBER(6, 0),
    message       VARCHAR2(2000)
);

COMMENT ON COLUMN error_log.module_name IS
    '30 characters only in Oracle. Use DESCRIBE all_tab_columns for more information';

ALTER TABLE error_log
    ADD CONSTRAINT error_log_pk PRIMARY KEY ( code,
                                              module_user,
                                              created_on );
*/

--DROP TABLE error_log;

--DESCRIBE all_tab_columns;

/*
CREATE TABLE error_message (
    code     NUMBER(6, 0) UNIQUE,
    message  VARCHAR2(2000)
);

INSERT ALL
INTO error_message ( code, message ) VALUES ( -20001, 'Trying to assign bad values.')
INTO error_message ( code, message ) VALUES ( -20002, 'Newline character is missing. Use CHR(13).' )
INTO error_message ( code, message ) VALUES ( -20003, q'[Got negative athlete's results.]' )
SELECT * FROM DUAL;

COMMIT;
*/

--DROP TABLE error_message;