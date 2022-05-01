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
        // parameter를 받아 int를 반환
        public int intCheck(String s, int defaultInt){
            if("".equals(s) || s == null) return defaultInt;
            try{
                return Integer.parseInt(s);
            }catch(NumberFormatException e){
                return defaultInt;
            }
        }
    %>
    <%
        /////
        // 선
        /////
        // DB
        final String DRIVER = "com.mysql.cj.jdbc.Driver";
        final String URL = "jdbc:mysql://127.0.0.1:3306/book_ex?useSSL=false";
        final String USER = "root";
        final String PW = "rjsduq!1";
//        final String PW = "1234";
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

        // html
        String titleHTML = "";

        // action값이 안들어오면 WRT로 세팅
        action = (request.getParameter("action") == null) ? "WRT" : request.getParameter("action");
        System.out.println(action);
        if(!Arrays.asList(actions).contains(action)){
            message = "ERR_Path";
        }else{
            titleHTML = "MOD".equals(action) ? "글 수정" : "글 작성";
            // page, pageSize가 없거나 다른 값으로 들어온 경우 1, 10으로 세팅
            pag2 = intCheck(request.getParameter("page"), 1);
            pageSize = intCheck(request.getParameter("pageSize"), 10);

            // WRT가 아닌 경우 bno 값 세팅, bno를 받지 않았다면 튕구기
            if(!"WRT".equals(action)){
                bno = intCheck(request.getParameter("bno"), -1);
                if(bno < 0) message="ERR_Path";
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
                        message = "ERR_NoBoard";
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
        this_message = "<%=message%>";
        // 만일 해당 페이지에서 오류가 발생하면 처리
        if(this_message != null){
            if(this_message == "ERR_Path"){
                alert("올바른 경로로 접근하세요.");
                location.href="./home.jsp";
            }else if(this_message == "ERR_NoBoard"){
                alert("존재하지 않는 게시물입니다.");
                location.href="./list.jsp?page=<%=pag2%>&pageSize=<%=pageSize%>";
            }
        }
        $(window).load(()=>{
            $('#load').hide();
        })
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

            $("#write").on("click", function(){
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
                    content : content
                };
                // 답글 혹은 수정인 경우 JSON에 bno도 담아주기
                if(action == "REP" || action=="MOD"){
                    bno = $("#bno").val();
                    json_data.bno = bno;
                }
                // ajax를 sync로 전송하기 때문에, 미리 loading bar 보이기
                $("#load").show();
                setTimeout(()=>{
                    $.ajax({
                        type : 'POST',
                        url : 'proc.jsp',
                        header : {"content-type" : "application/json"},
                        data : json_data,
                        dataType : "JSON",
                        async : false,
                        complete : function(){
                            $("#load").hide();
                        },
                        success : function(result){
                            message_proc(result);
                        },
                        error: function(request){
                            message_proc(request.responseJSON);
                        },
                    });
                }, 1);
            })

            $("#list").on("click", function(){
                location.href='./list.jsp?page=' + page + '&pageSize=' + pageSize;
            })

            $("#delete").on("click", function(){
                if(confirm("정말로 삭제하시겠습니까?")){
                    // ajax를 sync로 전송하기 때문에, 미리 loading bar 보이기
                    $("#load").show();
                    // timeout을 1초를 안걸면 위의 show가 작동을 안함 왜 why?????
                    setTimeout(()=>{
                        $.ajax({
                            type : 'POST',
                            url : 'proc.jsp',
                            header : {"content-type" : "application/json"},
                            data : {
                                action : 'DEL',
                                bno : bno
                            },
                            dataType : "JSON",
                            async : false,
                            complete : function(){
                                $('#load').hide();
                            },
                            success : function(result){
                                message_proc(result);
                            },
                            error: function(request){
                                message_proc(request.responseJSON);
                            },
                        });
                    }, 1);
                }
            })

            $("#reply").on("click", function(){
                location.href="./board.jsp?page="+page+"&pageSize="+pageSize+"&bno="+bno+"&action=REP";
            })
        })
    </script>
</body>
</html>
