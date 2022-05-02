<%@ page import="java.util.Arrays" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.DriverManager" %>
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
    <link rel="stylesheet" href="./static/css/style.css">
    <link rel="stylesheet" href="./static/css/reset.css">
    <script src="https://code.jquery.com/jquery-1.11.3.js"></script>
</head>
<body>
    <%!
        // parameter를 받아 int를 반환
        public int intCheck(String s, int defaultInt){
            try{
                return Integer.parseInt(s);
            }catch(NumberFormatException e){
                return defaultInt;
            }
        }

        public void errorProc(PrintWriter pwr, String cause){
            pwr.println("<script>");
            if("Path".equals(cause)){
                pwr.println("alert('올바른 경로로 접근하세요.')");
                pwr.println("location.href='home.jsp'");
            }else if("NoBoard".equals(cause)){
                pwr.println("alert('게시물이 존재하지 않습니다.')");
                pwr.println("history.back()");
            }
            pwr.println("</script>");
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
//        final String PW = "rjsduq!1";
        final String PW = "1234";
        Connection con = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        String SQL = null;

        // VO
        String[] actions = {"WRT", "MOD", "DEL", "REP"};
        int pag2 = 0;
        int pageSize = 0;
        String action = "";
        int bno = 0;
        String title = "";
        String content = "";

        // html
        String titleHTML = "";
        PrintWriter pwr = response.getWriter();

        // action값이 안들어오면 WRT로 세팅
        action = (request.getParameter("action") == null || "".equals(request.getParameter("action"))) ? "WRT" : request.getParameter("action");
        if(!Arrays.asList(actions).contains(action)){
            errorProc(pwr, "Path");
        }else{
            titleHTML = "MOD".equals(action) ? "글 수정" : "글 작성";
            // page, pageSize가 없거나 다른 값으로 들어온 경우 1, 10으로 세팅
            pag2 = intCheck(request.getParameter("page"), 1);
            pageSize = intCheck(request.getParameter("pageSize"), 10);
            // WRT가 아닌 경우 bno 값 세팅, bno를 받지 않았다면 튕구기
            if(!"WRT".equals(action)){
                bno = intCheck(request.getParameter("bno"), -1);
                if(bno < 0){
                    errorProc(pwr, "Path");
                };
            }
            // action이 MOD인 경우 해당 bno가 있는지 확인
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
                        errorProc(pwr, "NoBoard");
                    }
                }catch(Exception e){
                    pwr.println("<script>");
                    pwr.println("alert('에러가 발생했습니다')");
                    pwr.println("location.href='error.jsp'");
                    pwr.println("</script>");
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
        }
    %>
    <div id="load">
        <img src="/static/img/loading.gif" alt="loading">
    </div>
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
            /////
            // 선언
            /////

            let title;
            let content;
            let bno = $("#bno").val();
            let action = $("#action").val();
            let page = $("#page").val();
            let pageSize = $("#pageSize").val();
            let loading_flag = false;
            let json_data = {};
            let ajax = function(json){
                $.ajax({
                    type : 'POST',
                    url : 'proc.jsp',
                    header : {"content-type" : "application/json"},
                    data : json,
                    dataType : "JSON",
                    beforeSend : function(){
                        $("#load").show();
                        loading_flag = true;
                    },
                    complete : function(){
                        $("#load").hide();
                        loading_flag = false;
                    },
                    success : function(result){
                        message_proc(result);
                    },
                    error: function(request){
                        message_proc(request.responseJSON);
                    },
                });
            }
            const action_type = {
                "WRT" : "등록",
                "MOD" : "수정",
                "DEL" : "삭제",
                "REP" : "답글 등록"
            }

            // ajax로 가져온 message에 따라 분기 처리를 위한 함수
            let message_proc = function(json){
                alert(json.result == "SUC" ? "성공적으로 " + action_type[json.action] + " 되었습니다." : json.message);
                if(json.path == "list") {
                    location.href= "list.jsp?page=" + page + "&pageSize="+pageSize;
                }else if(json.path == "home"){
                    location.href="home.jsp";
                }
            }

            // ###
            // # 이벤트
            // ###

            $("#write").on("click", function(){
                if(loading_flag) return;
                // 유효성 검사
                title = $("#title").val().trim();
                content = $("#content").val().trim();
                if(title == "" || content == "") {
                    alert("제목 혹은 본문 내용은 필수입니다.");
                    return;
                }
                if(title.length>256) alert("제목이 너무 길어요");
                let json_data = {
                    action : action,
                    title : title,
                    content : content,
                    bno : $("#bno").val(),
                };
                // ajax 호출
                ajax(json_data);
            })

            $("#list").on("click", function(){
                if(loading_flag) return;
                location.href='./list.jsp?page=' + page + '&pageSize=' + pageSize;
            })

            $("#delete").on("click", function(){
                if(loading_flag) return;
                if(confirm("정말로 삭제하시겠습니까?")){
                    action = 'DEL';
                    json_data = {
                        action : action,
                        bno : bno,
                    }
                    // ajax 호출
                    ajax(json_data);
                }
            })

            $("#reply").on("click", function(){
                if(loading_flag) return;
                location.href="./board.jsp?page="+page+"&pageSize="+pageSize+"&bno="+bno+"&action=REP";
            })

            // ####
            // # 초기화
            // ####

            $('#load').hide();
        })
    </script>
</body>
</html>
