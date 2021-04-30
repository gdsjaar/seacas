C    Copyright(C) 1999-2020 National Technology & Engineering Solutions
C    of Sandia, LLC (NTESS).  Under the terms of Contract DE-NA0003525 with
C    NTESS, the U.S. Government retains certain rights in this software.
C
C    See packages/seacas/LICENSE for details

      SUBROUTINE COLAPS (MXND, MXCORN, MLN, MXLOOP, NUID, XN, YN, ZN,
     &   LXK, KXL, NXL, LXN, ANGLE, LNODES, BNSIZE, NODE, KKKOLD,
     &   LLLOLD, NNNOLD, IAVAIL, NAVAIL, DONE, XMIN, XMAX, YMIN, YMAX,
     &   ZMIN, ZMAX, DEV1, LLL, KKK, NNN, LCORN, NCORN, NLOOP, NEXTN1,
     &   KLOOP, GRAPH, VIDEO, KREG, NOROOM, ERR)
C***********************************************************************

C  SUBROUTINE COLAPS = COLLAPSES A LOOP INTO TWO POSSIBLE LOOPS

C***********************************************************************

      COMMON /TIMING/ TIMEA, TIMEP, TIMEC, TIMEPC, TIMEAJ, TIMES

      DIMENSION XN (MXND), YN (MXND), ZN (MXND), NUID (MXND)
      DIMENSION LXK (4, MXND), KXL (2, 3*MXND)
      DIMENSION NXL (2, 3*MXND), LXN (4, MXND)
      DIMENSION ANGLE (MXND), LNODES (MLN, MXND), BNSIZE (2, MXND)
      DIMENSION LCORN (MXCORN)
      DIMENSION NLOOP (MXLOOP), NEXTN1 (MXLOOP)

      CHARACTER*3 DEV1

      LOGICAL DONE, ERR, NOROOM, DONE1, DONE2, DONEP
      LOGICAL GRAPH, BOK, LCROSS, LMATCH, VIDEO
      LOGICAL CGRAPH, CWEDGE, PMATCH

      PI = ATAN2(0.0, -1.0)

C  FIND THE FIRST OVERLAPPING LINE STARTING AT THE CURRENT NODE

      CALL GETIME (TIME1)
      CGRAPH = .FALSE.
      CWEDGE = .TRUE.
      DONE1 = .FALSE.
      DONE2 = .FALSE.
      DONEP = .FALSE.
      PMATCH = .FALSE.
      ERR = .FALSE.
  100 CONTINUE
      N1 = NODE
      KOUNT1 = 0

      IF (CGRAPH) THEN
         CALL RPLOTL (MXND, XN, YN, ZN, NXL, XMIN, XMAX,
     &      YMIN, YMAX, ZMIN, ZMAX, LLL, DEV1, KREG)
      ENDIF

  110 CONTINUE
      N0 = LNODES (2, N1)
      N2 = LNODES (3, N1)
      N3 = LNODES (3, N2)
      KOUNT1 = KOUNT1 + 1

C  CHECK FOR COMPLETION

      IF (N2 .EQ. NODE) THEN
         GOTO 140
      ELSEIF (KOUNT1 .GT. NLOOP (1) + 1) THEN
         CALL MESAGE ('** PROBLEMS WITH LOOP CLOSING IN COLAPS **')
         ERR = .TRUE.
         GOTO 140
      ENDIF

C  CHECK THIS LINE AGAINST ALL REMAINING LINES

      KOUNT2 = 2
      N1TEST = LNODES (3, N2)
  120 CONTINUE
      N0TEST = LNODES (2, N1TEST)
      N2TEST = LNODES (3, N1TEST)
      N3TEST = LNODES (3, N2TEST)

      IF (CGRAPH) THEN
         CALL LCOLOR ('YELOW')
         CALL D2NODE (MXND, XN, YN, N1, N2)
         CALL D2NODE (MXND, XN, YN, N1TEST, N2TEST)
         CALL LCOLOR ('WHITE')
         CALL SFLUSH
      ENDIF

      CALL INTSCT (XN(N1), YN(N1), XN(N2), YN(N2), XN(N1TEST),
     &   YN(N1TEST), XN(N2TEST), YN(N2TEST), U, W, LCROSS)
      IF (.NOT. LCROSS) THEN
         IF (CGRAPH) THEN
            CALL D2NODE (MXND, XN, YN, N1, N2)
            CALL D2NODE (MXND, XN, YN, N1TEST, N2TEST)
            CALL SFLUSH
         ENDIF
         N1TEST = N2TEST
         KOUNT2 = KOUNT2 + 1
         IF (KOUNT2 .GT. ( NLOOP (1) / 2) ) THEN
            N1 = N2
            GOTO 110
         ENDIF
         GOTO 120
      ENDIF

C  AN INTERSECTION HAS OCCURRED.
C  GET THE BEST SEAM FROM THIS INTERSECTION

      IF ((GRAPH) .OR. (VIDEO)) THEN
         IF (.NOT. DONEP) THEN
            CALL RPLOTL (MXND, XN, YN, ZN, NXL, XMIN, XMAX,
     &         YMIN, YMAX, ZMIN, ZMAX, LLL, DEV1, KREG)
            DONEP = .TRUE.
            IF (VIDEO) CALL SNAPIT (1)
         ENDIF
         IF (GRAPH) THEN
            CALL LCOLOR ('YELOW')
            CALL D2NODE (MXND, XN, YN, N1, N2)
            CALL D2NODE (MXND, XN, YN, N1TEST, N2TEST)
            CALL LCOLOR ('WHITE')
            CALL SFLUSH
         ENDIF
      ENDIF
      CALL MATCH2 (MXND, MLN, XN, YN, NXL, LXN, LNODES, ANGLE, N0, N1,
     &   N2, N3, N0TEST, N1TEST, N2TEST, N3TEST, I1, I2, J1, J2,
     &   KOUNTL, LMATCH, KOUNT2, NODE, U, W, NLOOP (1), PMATCH, ERR)
      IF (ERR) GOTO 140
      IF (GRAPH) THEN
         CALL LCOLOR ('PINK ')
         CALL D2NODE (MXND, XN, YN, I1, I2)
         CALL D2NODE (MXND, XN, YN, J1, J2)
         CALL LCOLOR ('WHITE')
         CALL SFLUSH
      ENDIF
      IF (.NOT. LMATCH) THEN
         N1TEST = N2TEST
         KOUNT2 = KOUNT2 + 1
         IF (KOUNT2 .GT. ( NLOOP (1) / 2) ) THEN
            N1 = N2
            GOTO 110
         ENDIF
         GOTO 120
      ENDIF

C  NOW CHECK TO SEE IF THE ATTACHMENT WOULD CAUSE
C  LINES ON THE BOUNDARY TO CROSS

      CALL BCROSS (MXND, MLN, XN, YN, ZN, LXK, KXL, NXL, LXN, LNODES,
     &   I1, I2, J1, J2, NLOOP(1), BOK, LLL, XMIN, XMAX, YMIN, YMAX,
     &   ZMIN, ZMAX, DEV1, KREG, ERR)
      IF (ERR) GOTO 140
      IF (.NOT. BOK) THEN
         N1TEST = N2TEST
         KOUNT2 = KOUNT2 + 1
         IF (KOUNT2 .GT. ( NLOOP (1) / 2) ) THEN
            N1 = N2
            GOTO 110
         ENDIF
         GOTO 120
      ENDIF

C  NOW CHECK TO SEE IF THE ATTACHMENT WOULD CAUSE
C  AN ILLFORMED 4 NODE ELEMENT

      CALL B4BAD (MXND, MLN, XN, YN, LXK, KXL, NXL, LXN, LNODES,
     &   ANGLE, I1, I2, J1, J2, NLOOP(1), KOUNTL, BOK, ERR)
      IF (ERR) GOTO 140
      IF (.NOT. BOK) THEN
         N1TEST = N2TEST
         KOUNT2 = KOUNT2 + 1
         IF (KOUNT2 .GT. ( NLOOP (1) / 2) ) THEN
            N1 = N2
            GOTO 110
         ENDIF
         GOTO 120
      ENDIF

C  SEE IF THE COLLAPSE IS BETWEEN TWO ELEMENT SIDES OF DISPROPORTIONATE
C  SIZES - IF SO A WEDGE MUST BE ADDED

      DISTI = SQRT ( ((XN (I1) - XN (I2)) **2) +
     &   ((YN (I1) - YN (I2)) **2) )
      DISTJ = SQRT ( ((XN (J1) - XN (J2)) **2) +
     &   ((YN (J1) - YN (J2)) **2) )
      FACT = 2.5
      IF ( (DISTI .GT. FACT * DISTJ) .AND.
     &   ((LXN (3, J1) .GT. 0) .OR. (LXN (2, J1) .LT. 0)) .AND.
     &   ((LXN (3, J2) .GT. 0) .OR. (LXN (2, J2) .LT. 0)) ) THEN
         AHOLD = ANGLE (I2)
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      LNODES (2, I2), ERR)
         IF (ERR) GOTO 140
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      LNODES (2, LNODES (2, I2)), ERR)
         IF (ERR) GOTO 140
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      LNODES (3, I2), ERR)
         IF (ERR) GOTO 140
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      LNODES (3, LNODES (3, I2)), ERR)
         IF (ERR) GOTO 140
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      I2, ERR)
         IF (ERR) GOTO 140
         CALL WEDGE (MXND, MLN, NUID, LXK, KXL, NXL, LXN, XN, YN,
     &      LNODES, BNSIZE, IAVAIL, NAVAIL, LLL, KKK, NNN, LLLOLD,
     &      NNNOLD, I2, IDUM, NLOOP (1), CWEDGE, GRAPH, VIDEO, NOROOM,
     &      ERR)
         IF ((NOROOM) .OR. (ERR)) GOTO 140
         IF (VIDEO) CALL SNAPIT (2)
         KOUNTL = KOUNTL + 1
         I1 = I2
         I2 = LNODES (3, I1)
         ANGLE (LNODES (3, I2)) = AHOLD
         ANGLE (I1) = PI
         ANGLE (I2) = PI
         GOTO 100
      ELSEIF ( (DISTJ .GT. FACT * DISTI) .AND.
     &   ((LXN (3, I1) .GT. 0) .OR. (LXN (2, I1) .LT. 0)) .AND.
     &   ((LXN (3, I2) .GT. 0) .OR. (LXN (2, I2) .LT. 0)) ) THEN
         AHOLD = ANGLE (J2)
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      LNODES (2, J2), ERR)
         IF (ERR) GOTO 140
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      LNODES (2, LNODES (2, J2)), ERR)
         IF (ERR) GOTO 140
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      LNODES (3, J2), ERR)
         IF (ERR) GOTO 140
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      LNODES (3, LNODES (3, J2)), ERR)
         IF (ERR) GOTO 140
         CALL MARKSM (MXND, MLN, LXK, KXL, NXL, LXN, LNODES,
     &      J2, ERR)
         IF (ERR) GOTO 140
         CALL WEDGE (MXND, MLN, NUID, LXK, KXL, NXL, LXN, XN, YN,
     &      LNODES, BNSIZE, IAVAIL, NAVAIL, LLL, KKK, NNN, LLLOLD,
     &      NNNOLD, J2, IDUM, NLOOP (1), CWEDGE, GRAPH, VIDEO, NOROOM,
     &      ERR)
         IF ((NOROOM) .OR. (ERR)) GOTO 140
         IF (VIDEO) CALL SNAPIT (2)
         KOUNTL = KOUNTL + 1
         J1 = J2
         J2 = LNODES (3, J1)
         ANGLE (LNODES (3, J2)) = AHOLD
         ANGLE (J1) = PI
         ANGLE (J2) = PI
         GOTO 100
      ENDIF

C  NOW THAT THE APPROPRIATE COLLAPSE HAS BEEN FOUND, THE TWO LINES
C  MUST BE JOINED.

      CALL SEW2 (MXND, MLN, NUID, LXK, KXL, NXL, LXN, LNODES,
     &   IAVAIL, NAVAIL, LLL, KKK, NNN, I1, I2, J1, J2, NOROOM, ERR)
      IF ((NOROOM) .OR. (ERR)) GOTO 140

C  NOW SMOOTH AND PLOT THE CURRENT MESH

      NNN2 = 1
      CALL GETIME (TIME2)
      TIMEC = TIMEC + TIME2 - TIME1
      CALL FILSMO  (MXND, MLN, XN, YN, ZN, LXK, KXL, NXL, LXN,
     &   LLL, NNN, NNN2, LNODES, BNSIZE, NLOOP (1), XMIN, XMAX, YMIN,
     &   YMAX, ZMIN, ZMAX, DEV1, KREG)
      CALL GETIME (TIME1)
      IF ((GRAPH) .OR. (VIDEO)) THEN
         CALL RPLOTL (MXND, XN, YN, ZN, NXL, XMIN, XMAX,
     &      YMIN, YMAX, ZMIN, ZMAX, LLL, DEV1, KREG)
         IF (VIDEO) CALL SNAPIT (1)
         IF (GRAPH) THEN
            CALL LCOLOR ('YELOW')
            CALL D2NODE (MXND, XN, YN, I1, I2)
            CALL LCOLOR ('WHITE')
            CALL SFLUSH
         ENDIF
      ENDIF
      NLOOP1 = KOUNTL
      NLOOP2 = NLOOP (1) - KOUNTL - 2

C  NOW UPDATE THE DEFINITIONS OF NODE FOR BOTH LOOPS

      IF (J1 .EQ. NODE) THEN
         NODE = I2
      ELSEIF (J2 .EQ. NODE) THEN
         NODE = I1
      ENDIF
      CALL NODE12 (MXND, MLN, LNODES, I1, I2, NLOOP1, NLOOP2,
     &   NODE1, NODE2, NODE, ERR)
      IF (ERR) GOTO 140

C  NOW TRY TO PINCH BOTH LOOPS

      CALL LUPANG (MXND, MLN, XN, YN, ZN, LXK, KXL, NXL, LXN, NLOOP1,
     &   ANGLE, LNODES, NODE2, LLL, XMIN, XMAX, YMIN, YMAX, ZMIN, ZMAX,
     &   DEV1, KREG, ERR)
      IF (ERR) GOTO 140
      IDUM1 = 0
      IDUM2 = 0
      CALL GETIME (TIME2)
      TIMEC = TIMEC + TIME2 - TIME1
      CALL PINCH (MXND, MXCORN, MLN, NUID, XN, YN, ZN, LXK, KXL, NXL,
     &   LXN, ANGLE, LNODES, BNSIZE, NODE2, NLOOP1, KKKOLD, LLLOLD,
     &   NNNOLD, IAVAIL, NAVAIL, DONE1, XMIN, XMAX, YMIN, YMAX, ZMIN,
     &   ZMAX, DEV1, LLL, KKK, NNN, LCORN, NCORN, IDUM1, IDUM2, GRAPH,
     &   VIDEO, KREG, NOROOM, ERR)
      IF ((NOROOM) .OR. (ERR)) GOTO 140
      CALL GETIME (TIME1)
      CALL LUPANG (MXND, MLN, XN, YN, ZN, LXK, KXL, NXL, LXN, NLOOP2,
     &   ANGLE, LNODES, NODE1, LLL, XMIN, XMAX, YMIN, YMAX, ZMIN, ZMAX,
     &   DEV1, KREG, ERR)
      IF (ERR) GOTO 140
      CALL GETIME (TIME2)
      TIMEC = TIMEC + TIME2 - TIME1
      CALL PINCH (MXND, MXCORN, MLN, NUID, XN, YN, ZN, LXK, KXL, NXL,
     &   LXN, ANGLE, LNODES, BNSIZE, NODE1, NLOOP2, KKKOLD, LLLOLD,
     &   NNNOLD, IAVAIL, NAVAIL, DONE2, XMIN, XMAX, YMIN, YMAX, ZMIN,
     &   ZMAX, DEV1, LLL, KKK, NNN, LCORN, NCORN, IDUM1, IDUM2, GRAPH,
     &   VIDEO, KREG, NOROOM, ERR)
      IF ((NOROOM) .OR. (ERR)) GOTO 140
      CALL GETIME (TIME1)

C  NOW HANDLE THE PLACEMENT OF THOSE LOOPS

      IF ((DONE1) .AND. (DONE2)) THEN
         DONE = .TRUE.
         GOTO 140
      ELSEIF (DONE1) THEN
         NLOOP (1) = NLOOP2
         NODE = NODE1
      ELSEIF (DONE2) THEN
         NLOOP (1) = NLOOP1
         NODE = NODE2
      ELSE

C  MOVE PREVIOUS LOOPS DOWN IN THE LIST

         KLOOP = KLOOP + 1
         DO 130 I = KLOOP, 3, -1
            NLOOP (I) = NLOOP (I - 1)
            NEXTN1 (I) = NEXTN1 (I - 1)
  130    CONTINUE
         NEXTN1 (KLOOP) = 0

C  INSERT THE TWO NEW LISTS AS THE TOP TWO - KEEPING NODE
C  THE SAME FOR ONE OF THE LOOPS

         NLOOP (1) = NLOOP1
         NLOOP (2) = NLOOP2
         NEXTN1 (2) = NEXTN1 (1)
         NEXTN1 (1) = NODE1
         NODE = NODE2
      ENDIF

C  NOW MAKE SURE THAT THE TOP LOOP DOES NOT NEED A COLAPS AGAIN

      GOTO 100

  140 CONTINUE
      CALL GETIME (TIME2)
      TIMEC = TIMEC + TIME2 - TIME1
      RETURN

      END