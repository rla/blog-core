:- module(blog_admin, []).

:- use_module(library(http/http_json)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_client), [ http_read_data/3 ]).
:- use_module(library(http/http_session)).
:- use_module(library(docstore)).

:- use_module(ar_router).
:- use_module(blog_doc).

% Sends the main admin HTML file.

:- route_get(admin, reply_file('admin.html')).

% Sends the given file as response.

:- route_get(admin/File, reply_file(File)).

reply_file(File, _):-
    module_property(blog_admin, file(ModFile)),
    file_directory_name(ModFile, ModDir),
    atomic_list_concat([ModDir, '/public/', File], FullPath),
    send_file(FullPath).

% Helper to authenticate the current request.
% Requires role admin.

auth(Next):-
    (   http_session_data(user(User)),
        memberchk(role(admin), User)
    ->  call(Next)
    ;   reply_error(101)).
    
% Gives all documents in the collection.
    
:- route_get(api/col/Col, [auth], doc_all(Col)).

doc_all(Col):-
    ds_all(Col, Docs),
    maplist(doc_to_json, Docs, Json),
    reply_success(Json).

% Stores new document in the collection.
% Replies back id.

:- route_post(api/col/Col/doc, [auth], doc_insert(Col)).

doc_insert(Col):-
    http_current_request(Req),
    http_read_data(Req, Json, []),
    json_to_doc(Json, Doc),
    ds_insert(Col, Doc, Id),
    reply_success(Id).
    
% Gives document type by collection name.

:- route_get(api/col/Col/type, [auth], col_type(Col)).

col_type(Col):-
    (   ds_find(types, name=Col, [Doc])
    ->  doc_to_json(Doc, Json),
        reply_success(Json)
    ;   reply_error(103)).
    
% Gives single document by id.

:- route_get(api/doc/Id, [auth], doc_get(Id)).

doc_get(Id):-
    (   ds_get(Id, Doc)
    ->  doc_to_json(Doc, Json),
        reply_success(Json)
    ;   reply_error(104)).
    
% Gives document type by document id.
    
:- route_get(api/doc/Id/type, [auth], doc_type(Id)).
    
doc_type(Id):-
    (   ds_collection(Id, Col),
        ds_find(types, name=Col, [Doc])
    ->  doc_to_json(Doc, Json),
        reply_success(Json)
    ;   reply_error(105)).
    
% Updates document by id.

:- route_put(api/doc/Id, [auth], doc_update(Id)).

doc_update(Id, Req):-
    http_read_data(Req, Json, []),
    json_to_doc(Json, Doc),
    (   memberchk('$id'(Id), Doc)
    ->  ds_update(Doc)
    ;   ds_update(['$id'(Id)|Doc])),
    reply_success(Id).

% Removes the given document.
% Replies back id.
    
:- route_del(api/doc/Id, [auth], doc_remove(Id)).
    
doc_remove(Id):-
    ds_remove(Id),
    reply_success(Id).

% Logins into the system with username/password.
% When logic succeeds, sends user id back.
% Otherwise sends error 102.
    
:- route_post(api/login, login).

login:-
    http_current_request(Req),
    http_read_data(Req, json(Data), []),
    memberchk(username=User, Data),
    memberchk(password=Pass, Data),
    (   Cond = (username=User, password=Pass),
        ds_find(users, Cond, [Doc])
    ->  prop_get('$id', Doc, Id),
        http_session_assert(user(Doc)),
        reply_success(Id)
    ;   reply_error(102)).
    

% Logs out from the system
    
:- route_get(api/logout, logout).

logout:-
    http_session_retractall(user(_)),
    reply_success(@(true)).

% Sends JSON response with Data
% and success.
    
reply_success(Data):-
    reply_json(json([status=success, data=Data])).

% Sends error JSON response with Code.
    
reply_error(Code):-
    reply_json(json([status=error, code=Code])).
