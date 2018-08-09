% The KB provides:
% - A set of facts to describe a weighted undirected graph.
%	Each fact has the form edge(n1,n2,c),
%	stating that there is an undirected edge
%	between n1 and n2 whose cost is number c;
% - a predicate conn(N1,N2,C) that is true whenever N1 and N2 are nodes that
%	are different from each other, and connected via an edge with cost C
% - a predicate graph_nodes(L) that is true when L is the set of nodes in the graph

%%%%%%
use_module(library(ugraph)).

connection(N1,N2,Cost):-edge(N1,N2,Cost),\+(N1=N2).
connection(N1,N2,Cost):-edge(N2,N1,Cost),\+(N1=N2).

incomplete_node_list(L,N):-
	connection(N,_,_),
	\+ (member(N,L)).

graph_nodes(Acc,L):-
	incomplete_node_list(Acc,N),!,
	graph_nodes([N|Acc],L).

graph_nodes(L,L).

graph_nodes(L):-
	graph_nodes([],L).


%%%%% DESCRIPTION OF THE GRAPH USING edge/3 FACTS %%%%
edge(s,n1,6).
edge(s,n3,3.1).
edge(n1,n3,2.4).
edge(n1,t,7).
edge(n2,n4,5).
edge(n3,n5,3.6).
edge(n5,t,2).
edge(n2,n3,3.3).
edge(s,n2,4).
edge(n4,n5,1).
edge(n4,t,2.2).
edge(n3,n4,5.2).

% is true if P is a path connecting S and T with total length L. For
% example, by asking all solutions of thequery ?-path(s,t,P,L), we
% should obtain all paths connecting s with t (with their respective lengths)

%This is an adaptation of the lab exercise solution from
% http://www.inf.unibz.it/dis/teaching/PP/ex/prolog_ex3_sol.zip
path(S,T,L,_,[edge(S,T)]) :- edge(S,T,L).

path(S,T,L,V,[edge(S,Z)|P]) :-
	edge(S,Z,L0), %should match an edge in the KB
	\+(S=T), %the starting node cannot be the end node i.e. node is not a path to itself
	\+(member(Z,V)), %the matched edge cannot be a member of the already existant path i.e. do not go backwards
    path(Z,T,L1,[S|V],P), %recursive call for next node
    L is L0 + L1. %add length of edge to accumulator

path(S,T,P,L) :-
	path(S,T,L,[],P).

spath(S, T, P, L) :-
    path(S, T, P, L),
    \+ (path(S, T, P1, L2), L2 =< L, P1 \= P).