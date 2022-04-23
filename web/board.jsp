<%@ page import="java.util.Arrays" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.DriverManager" %><%--
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
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/reset.css">
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

        // VO
        String[] actions = {"WRT", "MOD", "DEL", "REP", ""};
        int pag2 = 0;
        int pageSize = 0;
        String action = "";
        int bno = 0;
        String title = "";
        String content = "";
        String message = null;

        System.out.println(request.getParameter("bno"));
        System.out.println(request.getParameter("action"));
        System.out.println(Arrays.asList(actions).contains(request.getParameter("action")));
        if(request.getParameter("action") == null || !Arrays.asList(actions).contains(request.getParameter("action"))){
            message = "ERR_Path";
        }else{
            action = "".equals(request.getParameter("action")) ? "WRT" : request.getParameter("action");
            titleHTML = "MOD".equals(action) ? "글 수정" : "글 작성";
            if("MOD".equals(action)){
                bno = intCheck(request.getParameter("bno")) == true ? Integer.parseInt(request.getParameter("bno")) : 0;
                if(bno == 0) message="ERR_Path";
                try{
                    Class.forName(DRIVER);
                    con = DriverManager.getConnection(URL, USER, PW);
                    SQL = "SELECT title, content \n" +
                          "FROM TBL_BOARD \n" +
                          "WHERE bno = " + bno + "\n" +
                          "AND blind_yn = 'N'";
                    pstmt = con.prepareStatement(SQL);
                    rs = pstmt.executeQuery();
                    if(rs.next()){
                        title = rs.getString(1);
                        content = rs.getString(2);
                    }else{
                        message = "ERR_NoBoard";
                    }
                }catch(Exception e){
                    e.printStackTrace();
                }
            }
        }
    %>
    <%if(message !=""){%>
    <script>
        location.href="proc.jsp?message=" + message;
    </script>
    <%}%>
    <div class="header">
        <div class="logo">LOGO</div>
        <div class="navi">
            <a class="home navi_contents" href='./home.jsp'><div>HOME</div></a>
            <a class="board navi_contents active" href='./list.jsp'><div>BOARD</div></a>
            <a class="login navi_contents" href="#"><div>LOGIN</div></a>
        </div>
    </div>
    <div class="mainContainer">
        <div class="titleContainer">

            <h1 class="title bold"><%=titleHTML%></h1>
        </div>

        <form id="form">
            <input type="hidden" id="bno" name="bno" value="<%=bno%>"/>
            <input type="hidden" name="page" value="<%=pag2%>"/>
            <input type="hidden" name="pageSize" value="<%=pageSize%>"/>
            <input type="hidden" id="actionInput" name="action" value="<%=action%>"/>
            <div class="contentsContainer">
                <ul>
                    <li>
                        <p>제목</p>
                        <input type="text" id="title" name="title" value="<%=title%>" />
                    </li>
                    <li>
                        <p>내용</p>
                        <textarea id="content" name="content" ><%=content%></textarea>
                    </li>
                    <li class="buttonContainer">
                        <button type="button" id="list">목록</button>
                        <button type="button" id="write">등록</button>
                        <%if("MOD".equals(action)){ %>
                            <button type="button" id="delete">삭제</button>
                            <button type="button" id="reply">답글</button>
                        <%}%>
                    </li>
                </ul>
            </div>
        </form>
    </div>
    <script>
        $(document).ready(function(){

            $("#write").on("click", function(){
                let form = $("#form");
                const title = $("#title").val().trim();
                const content = $("#content").val().trim();
                if(title == "" || content == "") {
                    alert("제목 혹은 본문 내용은 필수입니다.");
                    return;
                }
                form.attr('action', './proc.jsp');
                form.attr('method', 'post');
                form.submit();
            })

            $("#list").on("click", function(){
                location.href='./list.jsp?page=${boardVO.page}&pageSize=${boardVO.pageSize}"/>';
            })

            $("#delete").on("click", function(){
                let form = $("#form");
                if(confirm("정말로 삭제하시겠습니까?")){
                    $("#actionInput").val("DEL");
                    form.attr('action', './proc.jsp');
                    form.attr('method', 'post');
                    form.submit();
                }
            })

            $("#reply").on("click", function(){
                let form = $("#form");
                $("#title").val("");
                $("#content").val("");
                $("#actionInput").val("REP");
                form.attr('action', './board.jsp');
                form.attr('method', 'get');
                form.submit();
            })
        })
    </script>
</body>
</html>
