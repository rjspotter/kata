using CSV
using DataFrames
using Pkg
using Query
using StatsBase
using Statistics

# const global dataframe = open("/home/ubuntu/data/kc_house_data/kc_house_data.csv") |> CSV.File |> DataFrame
const global dataframe = open("/home/ubuntu/data/house-prices-advanced-regression-techniques/train.csv") |> CSV.File |> DataFrame

# Feature Cleaning

function na_is_zero(old::String)
  @assert occursin(r"^NA|[0-9]+$", old)
  old == "NA" ? 0 : parse(Int64, old)
end

for x in [:LotFrontage, :MasVnrArea, :GarageYrBlt]
  tmp = dataframe[x] .|> na_is_zero
  deletecols!(dataframe, x)
  insertcols!(dataframe, 2, x => tmp)
end


const global label = :SalePrice



function inpartition(tup, val::Union{String, Char})
  (tup.first == val)
end

function inpartition(tup, val)
  (val >= tup.first && val < tup.second)
end

function generate_forrest(full_set, (probability, number, threashold, partition_size))

  # if the spread of values is large break them into pieces sized by the std deviation
  function large_partition(feature_values)
    acc = []
    step = feature_values |> std
    max = feature_values |> maximum
    fst = 0
    snd = (feature_values |> minimum) + step
    while snd < (max - 1)
      proposed = (first = fst, second = snd)
      if (filter(x -> inpartition(proposed, x), feature_values) |> size |> first) > 0
        push!(acc, proposed)
        fst = snd
      end
      snd = snd + step
    end
    proposed = (first = fst, second = Inf32)
    push!(acc, proposed)
    acc
  end

  # if the spread is small just break by unique values (but include down to 0 and up to infinity)
  function small_partition(feature_values)
    feature_values = sort(feature_values)
    acc = []
    fst = 0
    for i in unique(feature_values)
      snd = i
      proposed = (first = fst, second = snd)
      if (filter(x -> inpartition(proposed, x), feature_values) |> size |> first) > 0
        push!(acc, proposed)
        fst = snd
      end
    end
    proposed = (first = fst, second = Inf32)
    push!(acc, proposed)
    acc
  end

  # if the values are straings just partition by value
  function partition(feature_values::Array{Union{Missing, String}})
    map(x -> (first = x, second = x), feature_values)
  end

  # what kind of (numeric) partition should we do
  function partition(feature_values)
    if (feature_values |> unique |> length) > partition_size
      large_partition(feature_values)
    else
      small_partition(feature_values)
    end
  end

  function entropy(data)
    len = data |> length |> float
    function item_entropy(category)
      ratio = float(category) / len
      -1 * ratio * log2(ratio)
    end
    data |> countmap |> values |> v -> map(item_entropy, v) |> sum
  end

  function infogain(df, feature)
    function entropy_with_value(val)
      entropy(filter(x -> inpartition(val, x[feature]), df)[label])
    end
    baseline = entropy(df[label])
    values = df[feature] |> partition
    entropy_diff = values .|> entropy_with_value .|> y -> baseline - y
    l = length(values)
    if l < 1
      0
    else
      sum(entropy_diff) / l
    end
  end

  function gainz(df)
    acc = Dict()
    for n in names(df)
      if n == label
        #nop
      else
        acc[n] = infogain(df, n)
      end
    end
    acc
  end

  function next_feature(feature_entropies)
    function largest(a, b)
      if b.first == label
        a
      else
        a.second > b.second ? a : b
      end
    end
    candidate = reduce(largest, feature_entropies)
    candidate.first
  end

  function small_difference(df)
    min = (df[label] |> minimum)
    max = (df[label] |> maximum)
    (max - min) < threashold
  end

  function build_tree(df)
    if (df |> names |> size |> first) < 2 || small_difference(df)
      df[label]
    else
      feature = df |> gainz |> next_feature
      new_nodes = Dict()
      for v in partition(df[feature])
        subframe = filter(x -> inpartition(v, x[feature]), df)
        deletecols!(subframe, feature)
        subtree = build_tree(subframe)
        new_nodes[v] = subtree
      end
      Dict(feature => new_nodes)
    end
  end

  function random_tree_selection()
    acc = []
    for n in 1:number
      tmp = filter(row -> (rand(1:100) < probability), full_set)
      push!(acc, build_tree(tmp))
    end
    acc
  end

  random_tree_selection()
end

# Walk the generated trees
function treewalk(item, branch::Union, value=0)
  sum(branch) / length(branch)
end

function treewalk(item, branch::Array, value=0)
  sum(branch) / length(branch)
end

function treewalk(item, branch::Dict)
  ks = (branch |> keys |> collect)
  @assert (ks |> size |> first) == 1
  @assert (ks |> first |> typeof) == Symbol

  ky = ks |> first
  new_branch = branch[ky]
  value = item[ky]
  treewalk(item, new_branch, value)
end

function treewalk(item, branch::Dict, value)
  ks = (branch |> keys |> collect)
  @assert (ks |> size |> first) > 0
  matches = filter(x -> inpartition(x, value), ks)
  if isempty(matches)
    ky = sample(ks)
  else
    ky = matches |> first
  end
  new_branch = branch[ky]
  treewalk(item, new_branch)
end

test_set = copy(dataframe[1:292, :])
train_set = copy(dataframe[293:1460, :])

# trees = generate_forrest(train_set, 50, 10, 1000, 15);

function test_trees(trees)
  myerr = []
  missed_cnt = 0
  for i in 1:size(test_set, 1)
    item = test_set[i, :]
    predictions = []
    for t in trees
      try
        p = treewalk(item, t)
        push!(predictions, p)
      catch e
        println("caught an error: $e")
      end
      # bar = ! @isdefined p
      # if bar # || p == t.min || p == t.max
      #   println("#nop")
      # else
      #   push!(predictions, p)
      # end
    end
    @assert ! isempty(predictions)
    predict = mean(predictions)
    err = abs(log(predict) - log(item[label]))
    push!(myerr, err)
    # if err > 100000
    #   println(sort(predictions))
    #   println(predict)
    #   println(item[label])
    # end
  end
  println(missed_cnt)
  # println(sqrt(mean(myerr.^2.)))
  sqrt(mean(myerr.^2.))
end

generation = Dict()
for i in 1:5
  println(i)
  probability = rand(1:100)
  number = rand(1:25)
  threashold = rand(1:10000)
  partition_size = rand(5:35)
  args = (probability, number, threashold, partition_size)
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args
end

for i in 1:5
  scores = generation |> keys |> collect |> sort
  a = generation[scores[1]]
  b = generation[scores[2]]

  args = (a[1], a[2], a[3], b[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

  args = (a[1], a[2], b[3], a[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

  args = (a[1], b[2], a[3], a[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

  args = (b[1], a[2], a[3], a[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

  args = (a[1], a[2], b[3], b[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

  args = (a[1], b[2], a[3], b[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

  args = (b[1], a[2], a[3], b[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

  args = (a[1], b[2], b[3], b[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

  args = (b[1], a[2], b[3], b[4])
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args

end

# Dict{Any,Any} with 5 entries:
#   0.329141 => (75, 3, 9762, 17)
#   0.299757 => (12, 5, 9771, 25)
#   0.26881  => (72, 18, 4933, 29)
#   0.269774 => (65, 5, 7249, 11)
#   0.255723 => (27, 25, 8344, 13)

