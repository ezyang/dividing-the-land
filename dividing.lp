% Set up the grid.  Offset squares like in this puzzle
% are equivalent to hexagons, so I used the materials in
% https://www.redblobgames.com/grids/hexagons/
%
% In this puzzle, we'd prefer to do all our computation in axial, but
% the grid boundaries are annoying to define in axial.  So we kick off
% grounding by defining the grid with a plain old offset coordinates.
%
%     0,0  1,0  2,0
%   0,1  1,1  2,1  3,1
%     0,2  1,2  2,2
%   0,3  1,3  2,3  4,3

g_node(g(X, Y)) :- X = 0..6, Y = 0..7, Y \ 2 = 0.
g_node(g(X, Y)) :- X = 0..7, Y = 0..7, Y \ 2 = 1.

% And then, we convert all the coordinates into axial.  The benefit
% of axial is that you don't have to worry about parity; the
% indexing rules are uniform throughout.
%
%     0,0  1,0  2,0
%  -1,1  0,1  1,1
%    -1,2  0,2  1,2
%  -2,3 -1,3  0,3
%
% The intermediate g2a rule is not really necessary, but because I
% didn't want to recode the conversion formula in JavaScript
% so we dump it here so that the JavaScript can just read it off.

g2a(g(GX, Y), a((GX-(Y+(Y&1))/2), Y)) :- g_node(g(GX, Y)).
a_node(A) :- g_node(G), g2a(G, A).

% OK, now we define all of our puzzle pieces in axial.  Conventionally,
% the circled square is labeled 0,0 so we can use these as deltas.
% The visualization helped when inputting these because I could check if
% they were actually shaped correctly by coloring them in.

shapes(0, a(2, -1)).
shapes(0, a(0, 0)).
shapes(0, a(1, 0)).
shapes(0, a(0, 1)).
shapes(0, a(-1, 2)).
shapes(0, a(0, 2)).
shapes(0, a(1, 2)).

shapes(1, a(0, 0)).
shapes(1, a(0, -1)).
shapes(1, a(1, 0)).
shapes(1, a(1, -1)).
shapes(1, a(1, -2)).
shapes(1, a(-1, 0)).
shapes(1, a(-1, 1)).

shapes(2, a(0, 0)).
shapes(2, a(0, 1)).
shapes(2, a(-1, 0)).
shapes(2, a(-1, 1)).
shapes(2, a(-1, 2)).
shapes(2, a(-2, 0)).

shapes(3, a(0, 0)).
shapes(3, a(0, -1)).
shapes(3, a(0, 1)).
shapes(3, a(-1, 1)).
shapes(3, a(1, -1)).
shapes(3, a(1, -2)).
shapes(3, a(2, -2)).

shapes(4, a(0, 0)).
shapes(4, a(-1, 0)).
shapes(4, a(-2, 0)).
shapes(4, a(-2, -1)).
shapes(4, a(-2, 1)).
shapes(4, a(-2, 2)).

shapes(5, a(0, 0)).
shapes(5, a(1, 0)).
shapes(5, a(2, 0)).
shapes(5, a(2, -1)).
shapes(5, a(3, -2)).

shapes(6, a(0, 0)).
shapes(6, a(0, -1)).
shapes(6, a(0, -2)).
shapes(6, a(-1, 0)).
shapes(6, a(-1, 1)).
shapes(6, a(1, -2)).

% Every shape is placed on the grid exactly once
{ place(S, A) : a_node(A) } = 1 :- shapes(S, _).

% Each square of the shape must overlap with a valid grid square
:- place(S, a(X, Y)), shapes(S, a(DX, DY)), not a_node(a(X+DX,Y+DY)).

% Once you've placed a shape, that colors each square in the shape
color(a(X+DX,Y+DY), S) :- place(S, a(X,Y)), shapes(S, a(DX,DY)).

% Coloring of squares is unique (aka, shapes cannot overlap).  One of
% the things as an ASP newbie that's not too clear to me is whether
% or not I should use cardinality constraints (like for place) or
% test constraints like below; which is more efficient.  For this puzzle
% it doesn't matter because the space is very small.
:- S1 != S2, color(A, S1), color(A, S2).

% Each placement also defines a place to read out the final answer.
% This also isn't needed for the solver but is here to help with
% the JavaScript.
readout(a(X, Y), S) :- place(S, a(X,Y)), shapes(S, a(0,0)).

% We write answers into the squares.  Writing in each character
% individually would be a pain, so we first define answer strings:

answer(0, "CURRANT").
%answer(1, "HANDSPAN").
answer(2, "ENSNARE").
answer(3, "FOUNTAIN").
answer(5, "FRACTURE").
answer(6, "QUARTER").
answer(7, "HEAVENLY").

% Then index out of the strings (using offset coordinates) to assign a
% letter to each grid entry.  Oddly enough gringo doesn't seem to have
% string indexing natively built in, so we embed something to do this
% for us.

#script (python)
import clingo
def index(s, i):
    return clingo.String(s.string[i.number])
#end.

g_letter(g(X, Y), @index(S, X)) :- g_node(g(X, Y)), answer(Y, S).
a_letter(A, C) :- g_letter(G, C), g2a(G, A).

% Letters within each shape must be unique
:- A1 != A2, color(A1, S), color(A2, S), a_letter(A1, C), a_letter(A2, C).

% That's all.  If running by hand, you only care about place/2, but
% we dump everything to feed JavaScript

% #show place/2.
