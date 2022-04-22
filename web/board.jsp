<%--
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
    <div class="header">
        <div class="logo">LOGO</div>
        <div class="navi">
            <a class="home navi_contents" href='<c:url value="/"/>'><div>HOME</div></a>
            <a class="board navi_contents active" href='<c:url value="/board/list"/>'><div>BOARD</div></a>
            <a class="login navi_contents" href="#"><div>LOGIN</div></a>
        </div>
    </div>
    <div class="mainContainer">
        <div class="titleContainer">
            <h1 class="title bold">${boardVO.action=="MOD" ? "글 수정" : "글 작성"}</h1>
        </div>

        <form id="form">
            <input type="hidden" id="bno" name="bno" value="${boardVO.bno}"/>
            <input type="hidden" name="page" value="${boardVO.page}"/>
            <input type="hidden" name="pageSize" value="${boardVO.pageSize}"/>
            <input type="hidden" id="actionInput" name="action" value="${boardVO.action}"/>
            <input type="hidden" id="parentBno" name="parentBno" value="${boardVO.parentBno}"/>
            <div class="contentsContainer">
                <ul>
                    <li>
                        <p>제목</p>
                        <input type="text" id="title" name="title" value="${boardVO.boardDTO.title}" />
                    </li>
                    <li>
                        <p>내용</p>
                        <textarea id="content" name="content" >${boardVO.boardDTO.content}</textarea>
                    </li>
                    <li class="buttonContainer">
                        <button type="button" id="list">목록</button>
                        <button type="button" id="write">등록</button>
                        <c:if test='${boardVO.action=="MOD"}'>
                            <button type="button" id="delete">삭제</button>
                            <button type="button" id="reply">답글</button>
                        </c:if>
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
                form.attr('action', '<c:url value="/board/proc"/>');
                form.attr('method', 'post');
                form.submit();
            })

            $("#list").on("click", function(){
                location.href='<c:url value="/board/list?page=${boardVO.page}&pageSize=${boardVO.pageSize}"/>';
            })

            $("#delete").on("click", function(){
                let form = $("#form");
                if(confirm("정말로 삭제하시겠습니까?")){
                    $("#actionInput").val("DEL");
                    form.attr('action', '<c:url value="/board/proc"/>');
                    form.attr('method', 'post');
                    form.submit();
                }
            })

            $("#reply").on("click", function(){
                let form = $("#form");
                $("#replyFlag").attr("checked", true);
                $("#title").val("");
                $("#content").val("");
                $("#actionInput").val("REP");
                form.attr('action', '<c:url value="/board/write"/>');
                form.attr('method', 'get');
                form.submit();
            })
        })
    </script>
</body>
</html>
