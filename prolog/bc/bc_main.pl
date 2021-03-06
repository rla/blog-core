:- module(bc_main, [
    bc_main/1, % +DatabaseFile
    bc_main/2  % +DatabaseFile, +Options
]).

/** <module> The main module
*/

:- set_prolog_flag(encoding, utf8).

:- use_module(bc_env).
:- use_module(bc_dep).

% Install hook to intercept messages
% about too old packs or SWI version.

user:message_hook(Term, _, _):-
    Term = error(bc_dep:_, _),
    message_to_string(Term, String),
    writeln(user_error, String),
    halt(1).

% Check that SWI and pack dependecies are met.

:- bc_check_dependencies.

:- load_settings('settings.db').

:- use_module(library(dcg/basics)).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_error)).
:- use_module(library(debug)).
:- use_module(library(docstore)).
:- use_module(library(arouter)).
:- use_module(library(st/st_expr)).
:- use_module(library(st/st_file)).
:- use_module(library(st/st_parse)).

% Log HTTP errors to stderr.

:- debug(http(error)).

:- use_module(bc_api).
:- use_module(bc_router).
:- use_module(bc_bust).
:- use_module(bc_view).
:- use_module(bc_admin).
:- use_module(bc_excerpt).
:- use_module(bc_data).
:- use_module(bc_migrate).
:- use_module(bc_search).
:- use_module(bc_mail_queue).
:- use_module(bc_analytics).

% In development: most debug features.
% In production: enable simple-template and view caching.

:- if(bc_env_production).
    :- bc_view_enable_cache.
    :- bc_enable_expires.
    :- bc_mail_set_behavior(send).
:- else.
    :- write(user_error, 'Running in development mode!'), nl(user_error).
    :- debug(arouter).
    :- debug(docstore).
    :- debug(bc_data).
    :- debug(bc_migrate).
    :- debug(bc_router).
    :- debug(bc_view).
    :- debug(bc_bust).
    :- debug(bc_main).
    :- debug(bc_type).
    :- debug(bc_role).
    :- debug(bc_search).
    :- debug(bc_mail).
    :- debug(bc_comment).
    :- debug(bc_action).
    :- debug(bc_analytics).
:- endif.

% Sets up simple-template.

:- st_set_function(excerpt, 2, bc_excerpt).

:- dynamic(initialized/0).

%! bc_main(+File) is det.
%
% Opens docstore database and runs the
% frameworks setup code.

bc_main(_):-
    initialized, !.

bc_main(File):-
    bc_data_open(File),
    http_options(Options),
    debug(bc_main, 'running with HTTP options: ~w', [Options]),
    http_server(bc_route, Options),
    asserta(initialized).

% Settings for HTTP server.
% These settings are used when running the
% HTTP server through http_server/2
% through bc_main/1.

:- setting(port, number, 80, 'Port to run on.').

:- setting(workers, number, 16, 'Number of HTTP threads.').

:- setting(ip, atom, '0.0.0.0', 'Interface to bind to.').

%! http_options(-Options) is det.
%
% Collects options suitable for http_server/2.

http_options(Options):-
    port_option(Port),
    ip_option(Ip),
    workers_option(Workers),
    Options = [
        port(Ip:Port),
        workers(Workers) ].

%! port_option(-Port) is det.
%
% Finds the value for HTTP port.
% Attempts to use command-line option --port=<port>.
% Otherwise uses settings.db setting port.
% If settings.db does not exist, uses default value of 80.

port_option(Port):-
    current_prolog_flag(argv, Argv),
    (   find_port_option(Argv, Port)
    ->  true
    ;   setting(port, Port)).

find_port_option([Arg|Argv], Port):-
    atom_codes(Arg, Codes),
    (   phrase(port_option_parse(Port), Codes)
    ->  true
    ;   find_port_option(Argv, Port)).

port_option_parse(Port) -->
    "--port=", integer(Port), { Port > 0 }.

%! workers_option(-Workers) is det.
%
% Finds the value for HTTP workers.
% Attempts to use command-line option --workers=<count>.
% Otherwise uses settings.db setting workers.
% If settings.db does not exist, uses default value of 16.

workers_option(Workers):-
    current_prolog_flag(argv, Argv),
    (   find_workers_option(Argv, Workers)
    ->  true
    ;   setting(workers, Workers)).

find_workers_option([Arg|Argv], Workers):-
    atom_codes(Arg, Codes),
    (   phrase(workers_option_parse(Workers), Codes)
    ->  true
    ;   find_workers_option(Argv, Workers)).

workers_option_parse(Workers) -->
    "--workers=", integer(Workers), { Workers > 0 }.

%! ip_option(-Ip) is det.
%
% Finds the value for HTTP workers.
% Attempts to use command-line option --ip=<ip>.
% Otherwise uses settings.db setting ip.
% If settings.db does not exist, uses default value of 0.0.0.0.

ip_option(Ip):-
    current_prolog_flag(argv, Argv),
    (   find_ip_option(Argv, Ip)
    ->  true
    ;   setting(ip, Ip)).

find_ip_option([Arg|Argv], Ip):-
    atom_codes(Arg, Codes),
    (   phrase(ip_option_parse(Ip), Codes)
    ->  true
    ;   find_ip_option(Argv, Ip)).

ip_option_parse(Ip) -->
    "--ip=", nonblanks(Codes), { atom_codes(Ip, Codes) }.

%! bc_main(+File, +Options) is det.
%
% Same as bc_main/1 but does not use
% options system. Options are directly
% passed to http_server/2.

bc_main(_, _):-
    initialized, !.

bc_main(File, Options):-
    bc_data_open(File),
    http_server(bc_route, Options),
    asserta(initialized).
