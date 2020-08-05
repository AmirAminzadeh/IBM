000100200719
000700200719           DCL-F PHNREPORT PRINTER OFLIND(*IN01);
000800200326           DCL-F CUSTOMER20 DISK(*EXT) KEYED USAGE(*INPUT)
000900200326                 RENAME(CUSTOMER20:CUSTR);
001000200709                      // data structure for host variables from CONTACTS20
001001200719
001002200719                      DCL-DS CONTACTS20 EXT END-DS;
001100190314
001200190314                     // Standalone fields for indicator variables
001201200719
001202200720                     DCL-S INDLastCDate BINDEC(4:0);
001203200720                     DCL-S INDNextCDate BINDEC(4:0);
001204200719
001300190314
001400190314
001500190314
001600190314           DCL-S Dummy  Zoned(1);
001700190314
001800190314        //**************************************************************************
001900190314        //*                        ***   M A I N   R O U T I N E   ***
002000190314        //**************************************************************************
002100190314
002200070119                EXSR SummaryInfo;
002300200709                WRITE NEWPAGE;
002400200326                READ CUSTOMER20;
002500070119                DOW NOT %EOF;
002600070119                    EXSR SQLSelect;
002607200724                    IF PHNLDC = OldestDate;
002608200724                      HIGHLIGHT = '<-------';
002609200724                      ELSE;
002610200724                        HIGHLIGHT = '';
002611200724
002612200724                    ENDIF;
002700190313                    IF *IN01 = *ON;
002800200709                       Write NEWPAGE;
002900190313                       *IN01 = *OFF;
003000070119                    ENDIF;
003100200709                    Write RPTLINE;
003200200326                   READ CUSTOMER20;
003300070119                ENDDO;
003400190313                Write SUMMARY;
003500070119                *INLR = *ON;
003600070119                RETURN;
003700080923        //**********************************************************************
003800080923        //   S Q L S E L E C T   S U B R O U T I N E
003900080923   //   //********************************************************************
004000080923   //                  BEGSR    SQLSelect ;
004100080923   //    // A row from the contacts table that has the same customer number as t
004200200326   //    // read from the CUSTOMER20 file is retrieved to find out the last date
004300080923   //    // phone number, comments and the salesperson number.
004400080923   //
004500080923   //    //  The call back interval is added to the last date called to determin
004600080923   //    //  next date to call.  Since null values may be stored in the last dat
004700080923   //    // indicator variables are used.
004701200719
004702200719         EXEC SQL
004703200720              SELECT PHNLDC + PHNCIT DAYS,PHNLDC,CSTPHN, PHNCOM, CSTSLN
004704200720
004705200720             INTO   :NEXTCDATE  :INDNEXTCDATE, :PHNLDC :INDLastCDate,
004706200720                    :CSTPHN, :PHNCOM, :CSTSLN
004707200720             FROM   BCI433LIB/CONTACTW20
004708200720             WHERE CSTNUM =:CSTNUM;
004709200720             select;
004710200720               WHEN SQLSTATE = '00000';
004711200720                DUMMY=0;
004712200720               WHEN SQLSTATE = '02000';
004713200720                Cstphn ='NOT FOUND';
004714200720                NEXTCDATE=D'9999-09-09';
004715200720                PhnLDC=D'9999-09-09';
004716200720                PhnCom=*ALL'*';
004717200720                CstSln=*ALL'*';
004718200720               WHEN  %Subst(SQLSTate :1 :2) = '01';
004719200720                NEXTCDATE = D'9999-09-09';
004720200720                PhnLDC = D'9999-09-09';
004721200720                PhnCom = *ALL'*';
004722200720                CstSln = *ALL'*';
004723200720                CstPhn = 'Warning';
004724200720               OTHER;
004725200720                CstPhn = 'Error';
004726200720                NEXTCDATE = D'9999-09-09';
004727200720                PhnLDC = D'9999-09-09';
004728200720                PhnCom = *ALL'*';
004729200720                CstSln = *ALL'*';
004730200720             ENDSL;
004731200720
004732200720             IF IndLastCDate = -1;
004733200720              CSTPHN = 'UNKNOWN DATE';
004734200720              NEXTCDATE = D'9999-09-09';
004735200720              PHNLDC = D'9999-09-09';
004742200720             ENDIF;
004743200724             IF PHNLDC = OLDESTDATE;
004744200724               HIGHLIGHT = '<-------';
004745200724               ELSE;
004746200724                 HIGHLIGHT= '';
004747200724
004748200724             ENDIF;
004749200724
004800190314
004900190314
005000200719
006800190314
006900080923                         ENDSR ;
007000080923        //**********************************************************************
007100080923        // S U M M A R Y I N F O   S U B R O U T I N E
007200080923        //**********************************************************************
007300080923                         BEGSR  SummaryInfo;
007400200709        //  D E T E R M I N E   T O T A L S   F O R   CONTACTS20 & CUSTOMER20
007500190314
007600200719            EXEC SQL
007601200719            SELECT COUNT(*) INTO :CONTACTT
007602200719            FROM BCI433LIB/CONTACTS20;
007603200720            IF (SQLCODE <> 0) OR (SQLWN0='W');
007604200720              CONTACTT=-99999;
007605200720            ENDIF;
007606200719
007607200720
007700200720             EXEC SQL
007701200720         SELECT COUNT(*) INTO:CUSTOMERT
007702200720           FROM BCI433LIB/CUSTOMER20;
007703200720
007704200720       IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
007705200720         CUSTOMERT = -99999;
007706200720       ENDIF;
007800200719
008900190314
009000190314        // D E T E R M I N E   N U M B E R   O F   U N K N O W N   LAST   DATE CALLED
009100200719                        EXEC SQL
009101200719                                   SELECT COUNT(*)
009102200719                                     INTO :UNKNOWNT
009103200719                                     FROM BCI433LIB/CONTACTS20
009104200719                                     WHERE IndLastCDate IS NULL;
009107200719                                   IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
009108200719                                     UNKNOWNT =-99999;
009109200719                                   ENDIF;
009200190314
009300200719
010000190314
010100080923        //  D E T E R M I N E   O L D E S T   &  M O S T   R E C E N T  L A S T
010200080923
010300200719                         EXEC SQL
010301200719                                   SELECT MIN(PHNLDC) INTO :OLDESTDATE
010302200719                                     FROM BCI433LIB/CONTACTS20;
010303200719
010304200719                                   IF (SQLCODE <> 0) OR (SQLWN0 = 'W')
010305200719                                      AND (SQLWN2 <> 'W');
010306200719                                     OLDESTDATE = D'9999-09-09';
010307200719                                   ENDIF;
010308200719
010309200719                                 EXEC SQL
010310200719                                   SELECT MAX(PHNLDC) INTO :MOSTRECENT
010311200719                                     FROM BCI433LIB/CONTACTS20;
010312200719
010313200720                                  IF (SQLCODE <> 0) OR (SQLWN0 = 'W')
010316200719                                     AND (SQLWN2 <> 'W');
010317200719                                     MOSTRECENT = D'9999-09-09';
010318200719                                   ENDIF;
010400190314
010500200719
012000190314
012100080923       // D E T E R M I N E   T H E   U S E R   S E R V E R   &   T I M E S T A
012101200720
012102200720                         EXEC SQL
012103200720                           SELECT USER,
012104200720                             CURRENT TIMESTAMP,
012105200720                             CURRENT SERVER
012106200720                             INTO :User,
012107200720                             :TimeStamp,
012108200720                             :Server
012109200720                             FROM SYSIBM/SYSDUMMY1;
012110200720
012111200720
012112200720
012113200720
012114200720
012800080923                         ENDSR;
012801200720
012802200720
