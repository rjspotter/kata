-module(problem_1).

-compile(export_all).

create_list(Max) -> create_list(Max - 1, []).
create_list(0,List) -> List;
create_list(Max, List) -> create_list(Max - 1, [Max | List]).

split_list(L) ->
  Threes = [X || X <- L, (X rem 3) =:= 0],
  Fives = [X || X <- L, (X rem 5) =:= 0],
  Fifteens = [X || X <- L, (X rem 15) =:= 0],
  {Threes, Fives, Fifteens}.

sum(Max) ->
  L = create_list(Max),
  {Threes, Fives, Fifteens} = split_list(L),
  lists:sum(Threes) + lists:sum(Fives) - lists:sum(Fifteens).