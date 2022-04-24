<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %><%--
  Created by IntelliJ IDEA.
  User: yeop
  Date: 2022/04/09
  Time: 15:58
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
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
    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String SQL = null;
    int pag2 = intCheck(request.getParameter("page")) == false ? 1 : Integer.parseInt(request.getParameter("page"));
    int pageSize = intCheck(request.getParameter("pageSize")) == false ? 10 : Integer.parseInt(request.getParameter("pageSize"));
    int totalCnt = 0;
    int naviSize = 10;
    int startPage = 0;
    int endPage = 0;
    int finalEndPage = 0;
    int boardStartNumber = 0;
    boolean prev = false;
    boolean next = false;
    String active = "";
    String repTitle = "";
    try{
        Class.forName(DRIVER);
        con = DriverManager.getConnection(URL, USER, PW);

    }catch(Exception e){
        e.printStackTrace();
        System.out.println("connection error");
    }
    try{
        SQL = "SELECT COUNT(*) FROM TBL_BOARD WHERE blind_yn = 'N'";
        pstmt = con.prepareStatement(SQL);
        rs = pstmt.executeQuery();
        if(rs.next())totalCnt = rs.getInt(1);
        System.out.println(totalCnt);
        if(totalCnt != 0){
            startPage = (pag2 - 1) / naviSize * naviSize + 1;
            finalEndPage = (int)Math.ceil(((double)totalCnt / naviSize));
            endPage = startPage + naviSize - 1 > finalEndPage ? finalEndPage : startPage + pageSize - 1;
            boardStartNumber = totalCnt - (pag2 - 1) * pageSize;
            prev = startPage != 1 ? true : false;
            next = endPage < finalEndPage ? true : false;
        }
        pstmt.clearParameters();
    }catch(Exception e){
        e.printStackTrace();
        System.out.println("total error");
    }
    if(totalCnt != 0){
        try{
            SQL = "SELECT bno, step, title, writer, regdate  \n " +
                    "FROM tbl_board\n" +
                    "WHERE 1=1\n" +
                    "AND blind_yn = 'N'\n" +
                    "ORDER BY ref DESC, depth ASC\n" +
                    "LIMIT " + ((pag2 - 1) * pageSize) + ", " + pageSize ;
            pstmt = con.prepareStatement(SQL);
            rs = pstmt.executeQuery();
        }catch(Exception e){
            System.out.println("list get error");
            e.printStackTrace();
        }
    }


%>
<html>
<head>
    <title>BOARD</title>
    <link rel="stylesheet" href="./static/css/style.css">
    <link rel="stylesheet" href="./static/css/reset.css">
    <script src="https://code.jquery.com/jquery-1.11.3.js"></script>
</head>
<body>
    <% request.getParameter("hi"); %>
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
                <%
                    if(totalCnt != 0){
                        while(rs.next()){
                %>
                <tr>
                    <th scope="row"><%=rs.getInt(1)%></th>
                    <td class="table_title">
                        <a href="./board.jsp?page=<%=pag2%>&pageSize=<%=pageSize%>&bno=<%=rs.getInt(1)%>&action=MOD">
                        <%  if(rs.getInt(2) != 0) {
                            for(int i = 0; i < rs.getInt(2);i++) repTitle += "&nbsp;&nbsp;&nbsp;";
                        %>
                            <span class="reply_tag"><%=repTitle%>Re :</span>
                        <%
                            repTitle = "";}
                        %>
                            <%=rs.getString(3)%>
                        </a>
                    </td>
                    <td><%=rs.getString(4)%></td>
                    <td><%=rs.getString(5)%></td>
                </tr>
                    <% }
                    }else{
                        %>
                <tr><td colspan="7" class="center_txt">게시물이 없습니다.</td></tr>
                <% }%>
                </tbody>
            </table>
                    </div>
                </div>
            <% if(totalCnt != 0){%>
            <div class="page_wrap">
                <div class="page_nation">
                    <% if(prev){ %>
                    <a class="arrow prev" href="./list.jsp?page=<%=startPage - 1%>&pageSize=<%=pageSize%>">&lt;</a>
                    <% }%>
                    <% for(int i = startPage; i <= endPage; i++){
                        if(i == pag2) active = "active";%>
                    <a class="<%=active%>" href="./list.jsp?page=<%=i%>&pageSize=<%=pageSize%>"><%=i%></a>
                    <% } %>
                    <% if(next){ %>
                    <a class="arrow next" href="./list.jsp?page=<%=endPage - 1%>&pageSize=<%=pageSize%>">&gt;</a>
                    <% }%>
                </div>
            </div>
            <%}%>
        </div>
    </div>
    <%
        try{
            if(rs !=null) rs.close();
            if(pstmt !=null) pstmt.close();
            if(con !=null) con.close();
        }catch(Exception e){
            e.printStackTrace();
        }
    %>
    <script>
        $(document).ready(function(){

            $("#write_btn").on("click",function(){
                location.href='./board.jsp?page=<%=pag2%>&pageSize=<%=pageSize%>&action=WRT';
            })
        })
    </script>
</body>
</html>
