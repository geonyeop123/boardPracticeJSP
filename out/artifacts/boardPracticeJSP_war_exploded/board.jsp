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
    <link rel="stylesheet" href="./static/css/style.css">
    <link rel="stylesheet" href="./static/css/reset.css">
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
//        final String PW = "1234";
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



        if(request.getParameter("action") == null || !Arrays.asList(actions).contains(request.getParameter("action"))){
            message = "ERR_Path";
        }else{
            action = "".equals(request.getParameter("action")) ? "WRT" : request.getParameter("action");
            titleHTML = "MOD".equals(action) ? "글 수정" : "글 작성";
            pag2 = intCheck(request.getParameter("page")) ? Integer.parseInt(request.getParameter("page")) : 1;
            pageSize = intCheck(request.getParameter("pageSize")) ? Integer.parseInt(request.getParameter("pageSize")) : 10;
            if(!"WRT".equals(action)){
                bno = intCheck(request.getParameter("bno")) == true ? Integer.parseInt(request.getParameter("bno")) : 0;
                if(bno == 0) message="ERR_Path";
            }
            if("MOD".equals(action)){
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
            <input type="hidden" id="page" name="page" value="<%=pag2%>"/>
            <input type="hidden" id="pageSize" name="pageSize" value="<%=pageSize%>"/>
            <input type="hidden" id="action" name="action" value="<%=action%>"/>
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
            let title;
            let content;
            let bno = $("#bno").val();
            let action = $("#action").val();
            let page = $("#page").val();
            let pageSize = $("#pageSize").val();
            let message_proc = function(message){
                if(message == ""){
                    alert("잘못된 접근입니다.");
                    location.href="./home.jsp";
                }
                const action_type = {
                    "WRT" : "등록",
                    "MOD" : "수정",
                    "DEL" : "삭제",
                    "REP" : "답글 등록"
                }
                // ERR_NoBoard -> NoBoard
                const code_name = message.substring(4);
                // ERR_NoBoard -> ERR
                const code_type = message.substring(0, 3);

                if(code_type == "SUC"){
                    alert("성공적으로 " + action_type[code_name] + "되었습니다.");
                    if(code_name!="MOD"){
                        location.href="./list.jsp?page=" + page + "&pageSize=" + pageSize;
                    }
                }else{
                    if(code_name == "NoBoard"){
                        alert("존재하지 않는 게시물입니다.");
                        location.href="./list.jsp?page=" + page + "&pageSize=" + pageSize;
                    }else if(code_name == "Path"){
                        alert("올바른 경로로 접근하세요.");
                        location.href="./home.jsp";
                    }else if(code_name == "HaveRep"){
                        alert("답글이 있는 경우 삭제할 수 없습니다.");
                    }else{
                        alert(action_type[code_name] + "도중 에러가 발생하였습니다.");
                    }
                }
            }

            $("#write").on("click", function(){
                title = $("#title").val().trim();
                content = $("#content").val().trim();
                if(title == "" || content == "") {
                    alert("제목 혹은 본문 내용은 필수입니다.");
                    return;
                }
                let json_data = {
                    action : action,
                    title : title,
                    content : content
                };
                if(action == "REP" || action=="MOD"){
                    bno = $("#bno").val();
                    json_data.bno = bno;
                }
                $.ajax({
                    type : 'POST',
                    url : 'proc.jsp',
                    header : {"content-type" : "application/json"},
                    data : json_data,
                    dataType : "JSON",
                    success : function(result){
                        message_proc(result.message);
                    },
                    error: function( request, status, error ){
                        alert("알 수 없는 오류가 발생하였습니다.");
                    }
                });
            })

            $("#list").on("click", function(){
                location.href='./list.jsp?page=' + page + '&pageSize=' + pageSize;
            })

            $("#delete").on("click", function(){
                if(confirm("정말로 삭제하시겠습니까?")){
                    $.ajax({
                        type : 'POST',
                        url : 'proc.jsp',
                        header : {"content-type" : "application/json"},
                        data : {
                            action : 'DEL',
                            bno : bno
                        },
                        dataType : "JSON",
                        success : function(result){
                            message_proc(result.message);
                        },
                        error: function(){
                            alert("알 수 없는 오류가 발생하였습니다.");
                        }
                    });
                }
            })

            $("#reply").on("click", function(){
                location.href="./board.jsp?page="+page+"&pageSize="+pageSize+"&bno="+bno+"&action=REP";
            })
        })
    </script>
</body>
</html>
