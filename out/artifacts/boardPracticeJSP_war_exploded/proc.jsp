<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="org.json.simple.JSONObject" %>
<%--
  Created by IntelliJ IDEA.
  User: yeop
  Date: 2022/04/09
  Time: 16:37
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <%!
        // 해당 값이 int형인지 체크하는 함수
        public int intCheck(String s, int defaultInt){
            if("".equals(s) || s == null){
                return defaultInt;
            }
            try{
                return Integer.parseInt(s);
            }catch(NumberFormatException e){
                return defaultInt;
            }
        }
    %>
    <%
        /////
        // 선언
        /////
        // DB
        final String DRIVER = "com.mysql.cj.jdbc.Driver";
        final String URL = "jdbc:mysql://127.0.0.1:3306/book_ex?useSSL=false";
        final String USER = "root";
        final String PW = "rjsduq!1";
//        final String PW = "1234";

        // DB
        Connection con = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        String SQL = null;
        int resultCnt = 0;

        // VO
        String[] actions = {"WRT", "MOD", "DEL", "REP"};
        String action = "";
        int bno = 0;
        String title = null;
        String content = null;
        String message = "";
        int currentRef = 0;
        int currentStep = 0;
        int currentDepth = 0;

        // html
        String titleHTML = "";

        // ajax 반환을 위한 변수

        JSONObject json = new JSONObject();
        response.setContentType("application/json;charset=utf-8");

        /////
        /// 유효성 검사
        /////
        try {
            Class.forName(DRIVER);
            con = DriverManager.getConnection(URL, USER, PW);
            con.setAutoCommit(false);
            // action 값 검사
            if (!Arrays.asList(actions).contains(request.getParameter("action"))) {
                throw new Exception("ERR_Path");
            } else {
                action = request.getParameter("action");
                System.out.println(action);
            }
            // bno 값 검사
            if (!"WRT".equals(action)) {
                bno = intCheck(request.getParameter("bno"), -1);
                if (bno < 0) {
                    message = "ERR_Path";
                } else {
                    SQL = "SELECT ref, step, depth " +
                            "FROM TBL_BOARD " +
                            "WHERE blind_yn = 'N' " +
                            "AND bno = " + bno;
                    pstmt = con.prepareStatement(SQL);
                    rs = pstmt.executeQuery();
                    pstmt.clearParameters();
                    // 해당 게시물이 없는 경우 에러 담기
                    if (!rs.next()) {
                        message = "ERR_NoBoard";
                    // 있는 경우 게시물 정보 담기
                    } else {
                        currentRef = rs.getInt(1);
                        currentStep = rs.getInt(2);
                        currentDepth = rs.getInt(3);
                    }
                }
            // WRT일 경우 쓰일 ref 가져오기
            } else {
                SQL = "SELECT IFNULL(MAX(ref), 0)+1 FROM TBL_BOARD B";
                pstmt = con.prepareStatement(SQL);
                rs = pstmt.executeQuery();
                if (rs.next()) currentRef = rs.getInt(1);
                pstmt.clearParameters();
            }

            // title, content 값 검사
            if (!"DEL".equals(action)) {
                title = request.getParameter("title");
                content = request.getParameter("content");
                if (title == null || content == null) message = "ERR_Path";
            }

            /////
            /// 로직
            /////

            if ("".equals(message)) {
                // 수정인 경우
                if ("MOD".equals(action)) {
                    SQL = "UPDATE TBL_BOARD SET title = ?, content = ? \n" +
                            "WHERE bno = ?";
                    pstmt = con.prepareStatement(SQL);
                    pstmt.setString(1, title);
                    pstmt.setString(2, content);
                    pstmt.setInt(3, bno);
                    resultCnt = pstmt.executeUpdate();
                    if(resultCnt > 0){
                        message = "SUC_MOD";
                        con.commit();
                    }else{
                        message = "ERR_MOD";
                        con.rollback();
                    }
                // 삭제인 경우
                } else if ("DEL".equals(action)) {
                    SQL = "SELECT count(*) "  +
                            "FROM tbl_board " +
                            "WHERE ref = ? "  +
                            "AND step > ? "   +
                            "AND depth = ? ";
                    pstmt = con.prepareStatement(SQL);
                    pstmt.setInt(1, currentRef);
                    pstmt.setInt(2, currentStep);
                    pstmt.setInt(3, currentDepth + 1);
                    rs = pstmt.executeQuery();
                    pstmt.clearParameters();
                    if (rs.next() && (rs.getInt(1) > 0)) {
                        message = "ERR_HaveRep";
                        con.rollback();
                    } else {
                        SQL = "UPDATE TBL_BOARD SET blind_yn = 'Y' \n" +
                                "WHERE bno = ?";
                        pstmt = con.prepareStatement(SQL);
                        pstmt.setInt(1, bno);
                        resultCnt = pstmt.executeUpdate();
                        if (resultCnt < 0) {
                            message = "ERR_DEL";
                            con.rollback();
                        } else {
                            SQL = "UPDATE TBL_BOARD SET depth = depth - 1 " +
                                    "WHERE ref = ? " +
                                    "AND depth > ? " +
                                    "AND blind_yn = 'N'";
                            pstmt = con.prepareStatement(SQL);
                            pstmt.setInt(1, currentRef);
                            pstmt.setInt(2, currentDepth);
                            pstmt.executeUpdate();
                            message = "SUC_DEL";
                            con.commit();
                        }
                    }
                // WRT, REP 인 경우
                } else {
                    SQL = "INSERT INTO TBL_BOARD(ref, step, depth, title, content, writer) " +
                            "VALUES( ?, ?, ?, ?, ?, ?)";
                    pstmt = con.prepareStatement(SQL);
                    pstmt.setInt(1, currentRef);
                    pstmt.setInt(2, "WRT".equals(action) ? 0 : currentStep + 1);
                    pstmt.setInt(3, "WRT".equals(action) ? 0 : currentDepth + 1);
                    pstmt.setString(4, title);
                    pstmt.setString(5, content);
                    pstmt.setString(6, "yeop");
                    resultCnt = pstmt.executeUpdate();
                    if(resultCnt > 0){
                        message = "SUC_" + action;
                        con.commit();
                    }else{
                        message = "ERR_" + action;
                        con.rollback();
                    }
                }
            }
        }catch(Exception e){
            System.out.println("e.getMessage() : " + e.getMessage());
            }finally{
                try{
                    if(rs !=null) rs.close();
                    if(pstmt !=null) pstmt.close();
                    if(con !=null) con.close();
                }catch(Exception e){
                    e.printStackTrace();
                }
            }

        /////
        /// 반환
        /////

        // 결과 값을 json으로 반환
        json.put("message", message);
        out.println(json);
    %>
