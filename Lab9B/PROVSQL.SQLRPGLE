000100190313       //**************************************************************************
000200191105       //* THIS PROGRAM USES A CURSOR TO LOAD A TEMPORARY RESULT TABLE FROM 3
000300191105       //* SEPARATE TABLES, ONTARIO, QUEBEC AND MANITOBA. A NUMBER IS PASSED
000400191105       //* TO THE PROGRAM TO DETERMINE WHICH RECORDS ARE INLCUDED FROM THE 3 TABLES
000500190313       //**************************************************************************
000600190313           DCL-F PROVREPORT PRINTER OFLIND(*IN01) ;
000700190313           DCL-S ProvinceH    Char(10);
000800190313           DCL-S EndOfFile    IND;
000900190313           DCL-S TotalRecords PACKED(5:0) ;
001000190315             // LowLimit is passed to the program
001100200731                              DCL-PI MAIN EXTPGM('PROVSQLH');
001101200731                 LOWLIMITIN PACKED(15:5);
001102200731             END-PI;
001200190315
001300190315
001400190315             // All Host Variables available under a single name
001500190315
001600200731                                       DCL-DS CustomerRecord;
001601200731                    CUSTID CHAR(6);
001602200731                    FULLNAME CHAR(31);
001603200731                    CITY CHAR(20);
001604200731                    PURCHASE PACKED(7:2);
001605200731                    PDATE DATE;
001606200731                    PROVINCE CHAR(10);
001700190315
001800190315
001900190315
002000190315
002100190315
002200190313        End-Ds CustomerRecord;
002300070123     C/EJECT
002400070123     C**************************************************************************
002500070123     C*                        ***   M A I N   R O U T I N E   ***
002600070123     C**************************************************************************
002700070118      /FREE
002701200731                     LowLimit = LowLimitIn;
002800100309                EXSR PrepareFiles;
002900200709                Write ReportHdg;
003000200709                Write RColumns;
003100100309                EXSR GetRow;
003200190313                Write NewProv;
003300070209                ProvinceH = Province;
003400070202                DOW NOT EndOfFile;
003500190313                    IF *IN01 = *ON;
003600200731                        Write REPORTHDG;
003700200709                        Write RColumns;
003800190313                       *IN01 = *OFF;
003900070209                    ENDIF;
004000190315                    // Province may change
004100200731                                               IF PROVINCEH = PROVINCE;
004101200731                      WRITE DETAIL;
004102200731                      ELSE;
004103200731                        PROVINCEH = PROVINCE;
004104200731                        WRITE TOTALS;
004105200731                        TOTALPURCH = 0;
004106200731                        WRITE NEWPROV;
004107200731                       WRITE DETAIL;
004108200731                    ENDIF;
004200190315
004300190315
004400190315
004500190315
004600190315
004700190315
004800190315
004900190315
005000190315
005100190315
005200190313                    TotalPurch     = TotalPurch     + Purchase;
005300070202                    TotalRecords= TotalRecords + 1;
005400100309                    EXSR GetRow;
005500070119                ENDDO;
005600190313                Write Totals;
005700070202                EXSR   WRAPUP;
005800190313                Write UnderLimit;
005900070119                *INLR = *ON;
006000070119                RETURN;
006100100309        //**********************************************************************
006200100309        // O P E N F I L E S   S U B R O U T I N E
006300100309        //**********************************************************************
006400100309         BEGSR  PrepareFiles;
006500190315        // S E T   U P   T H E   T E M P O R A R Y   R E S U L T  STRUCTURE
006600190315
006700190315
006800200731                           EXEC SQL
006801200731                  DECLARE ALLPROVCURSOR CURSOR
006802200731                    FOR
006803200731                    SELECT CUSTID, TRIM(FNAME) || ' ' || LNAME AS FULLNAME,
006804200731                    CITY, PURCHASE, PDATE,
006805200731                    'Ontario' AS PROVINCE
006806200731                    FROM BCI433LIB/ONTARIO
006807200731                    WHERE PURCHASE > :LowLimit
006808200731                    UNION ALL
006809200731                    SELECT CUSTID, TRIM(FNAME) || ' ' || LNAME AS FULLNAME,
006810200731                    CITY, PURCHASE, PDATE,
006811200731                    'Quebec' AS PROVINCE
006812200731                    FROM BCI433LIB/QUEBEC
006813200731                    WHERE PURCHASE > :LowLimit
006814200731                    UNION ALL
006815200731                    SELECT CUSTID, TRIM(FNAME) || ' ' || LNAME AS FULLNAME,
006816200731                    CITY, PURCHASE, PDATE,
006817200731                    'Manitoba' AS PROVINCE
006818200731                    FROM BCI433LIB/MANITOBA
006819200731                    WHERE PURCHASE > :LowLimit
006820200731                    FOR READ ONLY;
006900190315
007000190315
007100190315
007200190315
007300190315
007400190315
007500190315
007600190315
007700190315
007800190315
007900190315
008000190315
008100190315
008200190315
008300190315
008400190315
008500190315
008600190315
008700190315
008800100309        // A   T E M P O R A R Y   R E S U L T   T A B L E   I S   C R E A T E D
008900100309
009000190315
009100200731                                             EXEC SQL
009101200731                      OPEN ALLPROVCURSOR;
009102200731                    IF SQLCODE <> 0 OR SQLWN0 = 'W';
009103200731                      ENDOFFILE = *ON;
009104200731                    ENDIF;
009200190315
009300190315
009400190315
009500190315
009600100309            ENDSR;
009700100309        //**********************************************************************
009800100309        //   G E T     R O W    S U B R O U T I N E
009900100309        //**********************************************************************
010000100309            BEGSR     GETROW;
010100100309
010200190315
010300200731                             EXEC SQL
010301200731                FETCH NEXT
010302200731                  FROM ALLPROVCURSOR
010303200731                INTO :CustomerRecord;
010304200731              IF SQLCODE <> 0 OR SQLWN0 = 'W';
010305200731                ENDOFFILE = *ON;
010306200731              ENDIF;
010400190315
010500190315
010600190315
010700190315
010800190315
010900190315
011000190315
011100100309             ENDSR;
011200100309        //**********************************************************************
011300100309        // W R A P U P     S U B R O U T I N E
011400100309        //**********************************************************************
011500100309           BEGSR WRAPUP;
011501200731
011502200731                          EXEC SQL
011503200731               CLOSE ALLPROVCURSOR;
011504200731
011505200731             IF SQLCODE <> 0 OR SQLWN0 = 'W';
011506200731               ENDOFFILE = *ON;
011507200731             ENDIF;
011508200731
011509200731             EXEC SQL
011510200731               SELECT COUNT(*)
011511200731                 INTO : OntTotal
011512200731                 FROM BCI433LIB/ONTARIO
011513200731                 WHERE PURCHASE <= :LOWLIMIT;
011514200731
011515200731             IF SQLCODE <> 0 OR SQLWN0 = 'W';
011516200731               OntTotal = -999;
011517200731             ENDIF;
011518200731
011519200731             EXEC SQL
011520200731               SELECT COUNT(*)
011521200731                 INTO :QUETOTAL
011522200731                 FROM BCI433LIB/QUEBEC
011523200731                 WHERE PURCHASE <= :LOWLIMIT;
011524200731
011525200731             IF SQLCODE <> 0 OR SQLWN0 = 'W';
011526200731               QueTotal = -999;
011527200731             ENDIF;
011528200731
011529200731             EXEC SQL
011530200731               SELECT COUNT(*)
011531200731                 INTO :MANTOTAL
011532200731                 FROM BCI433LIB/MANITOBA
011533200731                 WHERE PURCHASE <= :LOWLIMIT;
011534200731             IF SQLCODE <> 0 OR SQLWN0 = 'W';
011535200731               ManTotal = -999;
011536200731             ENDIF;
011600100309          ENDSR;
011700190315
011800190315
011900190315
012000190315
012100190315
012200190315
012300190315
012400190315
012500190315
012600190315
012700190315
012800190315
012900190315
013000190315
013100190315
