<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="org.json.simple.JSONObject" %>
<%@ page import="java.io.PrintWriter" %><%--
  Created by IntelliJ IDEA.
  User: yeop
  Date: 2022/04/09
  Time: 16:37
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>BOARD</title>
    <script src="https://code.jquery.com/jquery-1.11.3.js"></script>
</head>
<body>
    <%!
        // 해당 값이 int형인지 체크하는 함수
        public boolean intCheck(String s){
            if("".equals(s) || s == null){
                return false;
            }
            try{
                Integer.parseInt(s);
            }catch(NumberFormatException e){
                return false;
            }
            return true;
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
        //final String PW = "1234";

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
        String title = "";
        String content = "";
        String message = "";
        int currentRef = 0;
        int currentStep = 0;
        int currentDepth = 0;

        // html
        String titleHTML = "";

        // ajax 반환을 위한 변수
        String json = "";
        PrintWriter prw = response.getWriter();
        response.setContentType("application/json;charset=utf-8");

        // 지정된 action이외의 값 혹은 action이 없는 경우 튕구기
        action = Arrays.asList(actions).contains(request.getParameter("action")) ? request.getParameter("action") : "";
        if("".equals(action)){
            message = "ERR_Path";

        // 지정된 action인 경우 로직 실행
        }else {
            try {
                Class.forName(DRIVER);
                con = DriverManager.getConnection(URL, USER, PW);
                con.setAutoCommit(false);
            } catch (Exception e) {
                System.out.println("Connection error");
                e.printStackTrace();
            }
            title = request.getParameter("title");
            content = request.getParameter("content");
            try {
                if ("WRT".equals(action)) {
                    SQL = "INSERT INTO TBL_BOARD(ref, step, depth, title, content, writer)\n" +
                            "VALUES((SELECT IFNULL(MAX(bno), 0)+1 FROM TBL_BOARD B) , 0, 0, ?, ?, 'yeop')";
                    pstmt = con.prepareStatement(SQL);
                    pstmt.setString(1, title);
                    pstmt.setString(2, content);
                    resultCnt = pstmt.executeUpdate();
                    if(resultCnt > 0){
                        message = "SUC_WRT";
                        con.commit();
                    }else{
                        message = "ERR_WRT";
                        con.rollback();
                    }
                // WRT가 아닌 경우 특정 게시물과 연관이 있으므로, 해당 게시물이 있는지 확인
                } else {
                    // 가져온 bno가 값이 없거나 다른 값인 경우 튕구기
                    if (intCheck(request.getParameter("bno"))) {
                        bno = Integer.parseInt(request.getParameter("bno"));
                    } else {
                        message = "ERR_Path";
                    }
                    // bno가 정확한 값으로 들어온 경우 해당 bno의 게시물 가져오기
                    if("".equals(message)) {
                        SQL = "SELECT ref, step, depth " +
                                "FROM TBL_BOARD " +
                                "WHERE blind_yn = 'N' " +
                                "AND bno = " + bno;
                        pstmt = con.prepareStatement(SQL);
                        rs = pstmt.executeQuery();
                        // 해당 게시물이 없는 경우 에러 담기
                        if(!rs.next()){
                            message = "ERR_NoBoard";
                        // 있는 경우 게시물 정보 담기
                        }else {
                            currentRef = rs.getInt(1);
                            currentStep = rs.getInt(2);
                            currentDepth = rs.getInt(3);
                            pstmt.clearParameters();
                            // 수정인 경우 로직 실행
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
                                // 답글이 있는지 확인
                                SQL = "SELECT count(*)\n" +
                                        "FROM tbl_board\n" +
                                        "WHERE ref = " + currentRef + "\n" +
                                        "AND step > " + currentStep + "\n" +
                                        "AND depth = " + (currentDepth + 1);
                                pstmt = con.prepareStatement(SQL);
                                rs = pstmt.executeQuery();
                                if (rs.next()) {
                                    // 답글이 있는 경우 에러 담기
                                    if (rs.getInt(1) != 0) {
                                        message = "ERR_HaveRep";
                                    // 없는 경우 삭제 진행
                                    }else {
                                        pstmt.clearParameters();
                                        SQL = "UPDATE TBL_BOARD SET blind_yn = 'Y' \n" +
                                                "WHERE bno = " + bno;
                                        pstmt = con.prepareStatement(SQL);
                                        resultCnt = pstmt.executeUpdate();
                                        if(resultCnt <= 0){
                                            message = "ERR_DEL";
                                            con.rollback();
                                        }else{
                                            pstmt.clearParameters();
                                            // 삭제 후 하위 depth를 가진 게시물들의 depth를 1씩 감소
                                            SQL = "UPDATE TBL_BOARD SET depth = depth - 1 " +
                                                  "WHERE ref = " + currentRef + " " +
                                                  "AND depth > " + currentDepth + " " +
                                                  "AND blind_yn = 'N'";
                                            pstmt = con.prepareStatement(SQL);
                                            resultCnt += pstmt.executeUpdate();
                                        }
                                        if(resultCnt > 0){
                                            message = "SUC_DEL";
                                            con.commit();
                                        }else{
                                            message = "ERR_DEL";
                                            con.rollback();
                                        }
                                    }
                                }
                            // 답글인 경우
                            } else if ("REP".equals(action)) {
                                // 최상위 답글로 달기 위해 들어갈 위치보다 아래에 있는 게시물의 Depth를 1씩 증가
                                SQL = "UPDATE TBL_BOARD SET depth = depth + 1 \n" +
                                        "WHERE ref = " + currentRef + "\n" +
                                        "AND depth > " + currentDepth + "\n" +
                                        "AND blind_yn = 'N'";
                                pstmt = con.prepareStatement(SQL);
                                resultCnt = pstmt.executeUpdate();
                                pstmt.clearParameters();
                                // 이후 게시물 등록 진행
                                SQL = "INSERT INTO TBL_BOARD(ref, step, depth, title, content, writer)" +
                                        "VALUES( ?, ?, ?, ?, ?, ?)";
                                pstmt = con.prepareStatement(SQL);
                                pstmt.setInt(1, currentRef);
                                pstmt.setInt(2, currentStep + 1);
                                pstmt.setInt(3, currentDepth + 1);
                                pstmt.setString(4, title);
                                pstmt.setString(5, content);
                                pstmt.setString(6, "yeop");
                                resultCnt = pstmt.executeUpdate();
                                if(resultCnt > 0){
                                    message = "SUC_REP";
                                    con.commit();
                                }else{
                                    message = "ERR_REP";
                                    con.rollback();
                                }
                            }
                        }
                    }
                }
            }catch(Exception e){
                e.printStackTrace();
            }finally{
                try{
                    if(rs !=null) rs.close();
                    if(pstmt !=null) pstmt.close();
                    if(con !=null) con.close();
                }catch(Exception e){
                    e.printStackTrace();
                }
            }
        }
        // 결과 값을 json으로 반환
        json = "{\"message\":" +"\"" + message + "\""+ "}";
        prw.println(json);
        prw.close();
    %>
</body>
</html>
