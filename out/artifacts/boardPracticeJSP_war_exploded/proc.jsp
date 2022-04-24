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
        final String DRIVER = "com.mysql.cj.jdbc.Driver";
        final String URL = "jdbc:mysql://127.0.0.1:3306/book_ex?useSSL=false";
        final String USER = "root";
        final String PW = "rjsduq!1";
        // html
        String titleHTML = "";

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
        String message = null;
        JSONObject object = new JSONObject();
        PrintWriter prw = response.getWriter();
        response.setContentType("application/json;charset=utf-8");

        int parentRef = 0;
        int parentStep = 0;
        int parentDepth = 0;


        action = Arrays.asList(actions).contains(request.getParameter("action")) ? request.getParameter("action") : null;
        if(action == null){
            message = "ERR_Path";
        }else{
            try{
                Class.forName(DRIVER);
                con = DriverManager.getConnection(URL, USER, PW);
            }catch(Exception e){
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
                    message = resultCnt == 1 ? "SUC_WRT" : "ERR_WRT";
                }else {
                    if(intCheck(request.getParameter("bno"))){
                        bno = Integer.parseInt(request.getParameter("bno"));
                        System.out.println("bno = " + bno);
                    }else{
                        message = "ERR_Path";
                    }
                    if(message==null){
                        SQL = "SELECT ref, step, depth " +
                                "FROM TBL_BOARD " +
                                "WHERE blind_yn = 'N' " +
                                "AND bno = " + bno;
                        pstmt = con.prepareStatement(SQL);
                        rs = pstmt.executeQuery();
                        message = rs.next() ? "" : "ERR_NoBoard";

                        parentRef = rs.getInt(1);
                        parentStep = rs.getInt(2);
                        parentDepth = rs.getInt(3);

                        pstmt.clearParameters();
                        if ("".equals(message)) {
                            if ("MOD".equals(action)) {
                                SQL = "UPDATE TBL_BOARD SET title = ?, content = ? \n" +
                                        "WHERE bno = ?";
                                pstmt = con.prepareStatement(SQL);
                                pstmt.setString(1, title);
                                pstmt.setString(2, content);
                                pstmt.setInt(3, bno);
                                resultCnt = pstmt.executeUpdate();
                                message = resultCnt == 0 ? "ERR_MOD" : "SUC_MOD";
                            }else if("DEL".equals(action)){
                                // 답글이 있는지 확인
                                SQL = "SELECT count(*)\n" +
                                        "FROM tbl_board\n" +
                                        "WHERE ref = " + parentRef + "\n" +
                                        "AND step > " +parentStep + "\n" +
                                        "AND depth = " + parentDepth+1;
                                pstmt = con.prepareStatement(SQL);
                                rs = pstmt.executeQuery();
                                if(rs.next()) if(rs.getInt(1) != 0){
                                    message = "ERR_HaveRep";
                                }else{
                                    pstmt.clearParameters();
                                    SQL = "UPDATE TBL_BOARD SET blind_yn = 'Y' \n" +
                                          "WHERE bno = " + bno;
                                    pstmt = con.prepareStatement(SQL);
                                    resultCnt = pstmt.executeUpdate();
                                    message = resultCnt == 0 ? "ERR_DEL" : "SUC_DEL";
                                }
                            }else if("REP".equals(action)){
                                SQL = "UPDATE TBL_BOARD SET depth = depth + 1 \n" +
                                      "WHERE ref = " + parentRef + "\n" +
                                      "AND depth > " + parentDepth;
                                pstmt = con.prepareStatement(SQL);
                                resultCnt = pstmt.executeUpdate();
                                pstmt.clearParameters();
                                SQL = "INSERT INTO TBL_BOARD(ref, step, depth, title, content, writer)" +
                                      "VALUES( ?, ?, ?, ?, ?, ?)";
                                pstmt= con.prepareStatement(SQL);
                                pstmt.setInt(1, parentRef);
                                pstmt.setInt(2, parentStep + 1);
                                pstmt.setInt(3, parentDepth + 1);
                                pstmt.setString(4, title);
                                pstmt.setString(5, content);
                                pstmt.setString(6, "yeop");
                                resultCnt = pstmt.executeUpdate();
                                message = resultCnt < 0 ? "ERR_REP" : "SUC_REP";
                            }
                        }
                    }
                }
            }catch(Exception e){
                e.printStackTrace();
            }
        }
        System.out.println(message);
        String st = "{\"message\":" +"\"" + message + "\""+ "}";
        prw.println(st);
        prw.close();


    %>
<%--    <script>--%>
<%--        $(document).ready(function(){--%>
<%--            // #####--%>
<%--            // # 변수 선언--%>
<%--            // #####--%>

<%--            const action_type = {--%>
<%--                "WRT" : "등록",--%>
<%--                "MOD" : "수정",--%>
<%--                "DEL" : "삭제",--%>
<%--                "REP" : "답글 등록"--%>
<%--            }--%>
<%--            const action = '<%=action%>';--%>
<%--            const msg = '<%=message%>';--%>
<%--            // ERR_NoBoard -> NoBoard--%>
<%--            const code_name = msg.substring(4);--%>
<%--            // ERR_NoBoard -> ERR--%>
<%--            const code_type = msg.substring(0, 3);--%>
<%--            // 유효성 검사--%>
<%--            if(msg == "" || action == ""){--%>
<%--                alert("잘못된 접근입니다.");--%>
<%--                location.href="./home.jsp";--%>
<%--                return;--%>
<%--            }--%>
<%--            // 코드가 ERR일 시--%>
<%--            if(code_type == "ERR"){--%>
<%--                if(code_name == "NoBoard"){--%>
<%--                    alert("존재하지 않는 게시물입니다.");--%>
<%--                    location.href ='./list.jsp?page=<%=pag2%>&pageSize=<%=pageSize%>';--%>
<%--                }else if(code_name == "Path"){--%>
<%--                    alert("올바른 경로로 접근하세요.");--%>
<%--                    location.href = "./home.jsp";--%>
<%--                }else if(code_name == "HaveRep"){--%>
<%--                    alert("답글이 있는 경우 삭제할 수 없습니다.");--%>
<%--                    location.href = './board.jsp?page=<%=pag2%>&pageSize=<%=pageSize%>&bno=<%=bno%>&action=MOD';--%>
<%--                // action 에러인 경우--%>
<%--                }else{--%>
<%--                    alert(action_type[code_name] + "도중 에러가 발생했습니다.");--%>
<%--                    <% action = "DEL".equals(action) ? "MOD" : action; %>--%>
<%--                    location.href='./board.jsp?page=<%=pag2%>&pageSize=<%=pageSize%>&bno=<%=bno%>&title=<%=title%>&content=<%=content%>&action=<%=action%>';--%>
<%--                }--%>
<%--            // 코드가 SUC일 시--%>
<%--            }else{--%>
<%--                alert("성공적으로 " + action_type[code_name] + "되었습니다.");--%>
<%--                // WRT일 시--%>
<%--                if(code_name == "WRT"){--%>
<%--                    location.href = "./list.jsp";--%>
<%--                // MOD일 시--%>
<%--                }else if(code_name == "MOD"){--%>
<%--                    location.href = './board.jsp?page=<%=pag2%>&pageSize=<%=pageSize%>&bno=<%=bno%>&action=MOD';--%>
<%--                // DEL, REP일 시--%>
<%--                }else{--%>
<%--                    location.href = './list.jsp?page=<%=pag2%>&pageSize=<%=pageSize%>';--%>
<%--                }--%>
<%--            }--%>
<%--        })--%>
<%--    </script>--%>
</body>
</html>
