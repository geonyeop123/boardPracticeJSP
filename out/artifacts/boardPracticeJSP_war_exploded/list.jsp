<%--
  Created by IntelliJ IDEA.
  User: yeop
  Date: 2022/04/09
  Time: 15:58
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.boardPracticeJSP.domain.BoardVO" %>
<html>
<head>
    <title>BOARD</title>
    <link rel="stylesheet" href="./static/css/style.css">
    <link rel="stylesheet" href="./static/css/reset.css">
    <script src="https://code.jquery.com/jquery-1.11.3.js"></script>
</head>
<body>
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
            <h1 class="title">게시판</h1>
            <div class="buttonContainer">
                <button id="write_btn" type="button">글쓰기</button>
            </div>
        </div>
        <div class="contentsContainer">
            <table class="board_table">
                <thead>
                <tr>
                    <th scope="cols">번호</th>
                    <th scope="cols">제목</th>
                    <th scope="cols">작성자</th>
                    <th scope="cols">작성일</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <th scope="row">2</th>
                    <td class="table_title">하이요</td>
                    <td>yeop</td>
                    <td>2021.01.12</td>
                </tr>
                <tr>
                    <th scope="row">2</th>
                    <td class="table_title">하이요</td>
                    <td>yeop</td>
                    <td>2021.01.12</td>
                </tr>
                </tbody>
            </table>
                    </div>
                </div>

        </div>
    </div>
    <script>
        $(document).ready(function(){

            $("#write_btn").on("click",function(){
                location.href='<c:url value="/board/write?page=${boardVO.pageMaker.page}&pageSize=${boardVO.pageMaker.pageSize}&action=WRT"/>';
            })
        })
    </script>
</body>
</html>
