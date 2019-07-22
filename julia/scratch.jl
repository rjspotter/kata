using CSV
using DataFrames
using Pkg
using Query
using StatsBase
using Statistics
using Tables

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

function gen_tester(decoder)
  function test_trees(trees)
    myerr = []
    missed_cnt = 0
    for i in 1:size(test_set, 1)
      item = test_set[i, :]
      predictions = []
      for t in trees
        try
          p = treewalk(item, t)
          push!(predictions, decoder(item, p))
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
end

# feature engineering
function gen_date_encoder(dataset)
  all_mean = mean(dataset[label])
  lookup = by(dataset, [:YrSold, :MoSold], mean = label => mean)

  function this_mean(feature_value)
    lookup[(lookup.YrSold .== feature_value[:YrSold]) .& (lookup.MoSold .== feature_value[:MoSold]), :mean] |> first
  end

  function date_encoder(feature_value)
    (feature_value[label] / all_mean) * this_mean(feature_value)
  end

  function date_decoder(feature_value, prediction)
    (prediction / this_mean(feature_value)) * all_mean
  end

  [date_encoder, date_decoder]
end

date_encoder, date_decoder = gen_date_encoder(train_set)

tmp = []
for i in (1:size(train_set, 1))
  push!(tmp, date_encoder(train_set[i, :]))
end

deletecols!(train_set, label)
insertcols!(train_set, 2, label => tmp)

test_trees = gen_tester(date_decoder)

generation = Dict()
for i in 1:4
  println(i)
  probability = rand(1:100)
  number = rand(1:25)
  threashold = rand(1:10000)
  partition_size = rand(5:35)
  args = (probability, number, threashold, partition_size)
  trees = generate_forrest(train_set, args);
  generation[test_trees(trees)] = args
end

println("one")
args = (20, 20, 1000, 10)
trees = generate_forrest(train_set, args);
generation[test_trees(trees)] = args

println("two")
args = (40, 10, 5000, 25)
trees = generate_forrest(train_set, args);
generation[test_trees(trees)] = args

println("three")
args = (60, 15, 10000, 20)
trees = generate_forrest(train_set, args);
generation[test_trees(trees)] = args

println("four")
args = (80, 5, 15000, 15)
trees = generate_forrest(train_set, args);
generation[test_trees(trees)] = args

println("hand")
args = (80, 20, 100, 12)
trees = generate_forrest(train_set, args);
generation[test_trees(trees)] = args


for i in 1:5
  println("############################## $i")
  scores = generation |> keys |> collect |> sort
  arglist = generation |> values |> collect
  best = scores[1]
  next_best = ()
  for j in 2:length(scores)
    if scores[j] == best || next_best != ()
      #n0p
    else
      next_best = scores[j]
    end
  end
  a = generation[best]
  b = generation[next_best]
  println(a)
  println(b)

  println("# children")
  args = (a[1], a[2], a[3], b[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (a[1], a[2], b[3], a[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (a[1], b[2], a[3], a[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (b[1], a[2], a[3], a[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (a[1], a[2], b[3], b[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (a[1], b[2], a[3], b[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (b[1], a[2], a[3], b[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (a[1], b[2], b[3], b[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (b[1], a[2], b[3], b[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  println("# like birds")
  random_key = generation |> keys |> collect |> rand
  c = generation[random_key]

  args = (a[1], c[2], a[3], a[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (c[1], a[2], a[3], a[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (a[1], a[2], c[3], c[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (a[1], c[2], a[3], c[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (c[1], a[2], a[3], c[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (a[1], c[2], c[3], c[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (c[1], a[2], c[3], c[4])
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  println("# mutants")
  # mutants
  r1 = rand(min(a[1], b[1]):max(a[1], b[1]))
  r2 = rand(min(a[2], b[2]):max(a[2], b[2]))
  r3 = rand(min(a[3], b[3]):max(a[3], b[3]))
  r4 = rand(min(a[4], b[4]):max(a[4], b[4]))

  args = (r1, r2, r3, r4)
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  r1 = rand(min(a[1], c[1]):max(a[1], c[1]))
  r2 = rand(min(a[2], c[2]):max(a[2], c[2]))
  r3 = rand(min(a[3], c[3]):max(a[3], c[3]))
  r4 = rand(min(a[4], c[4]):max(a[4], c[4]))

  args = (r1, r2, r3, r4)
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

  args = (rand(1:100), rand(1:35), rand(1:20000), rand(1:50))
  if (findall(x -> x == args, arglist) |> length) == 0
    println(args)
    trees = generate_forrest(train_set, args);
    generation[test_trees(trees)] = args
  end

end

# julia> generation |> keys |> collect |> sort |> first
# 0.2447208046533659

# julia> generation
# Dict{Any,Any} with 54 entries:
#   0.261363 => (76, 7, 1197, 6)
#   0.281518 => (40, 10, 5000, 25)
#   0.253996 => (40, 12, 5067, 6)
#   0.25875  => (40, 12, 5067, 7)
#   0.252379 => (40, 12, 4940, 6)
#   0.26178  => (44, 8, 2581, 7)
#   0.258522 => (40, 9, 5000, 6)
#   0.273226 => (76, 7, 5067, 6)
#   0.345439 => (11, 3, 18200, 23)
#   0.287219 => (60, 12, 10000, 20)
#   0.268524 => (40, 7, 4992, 6)
#   0.244721 => (40, 12, 4992, 6)
#   0.266494 => (40, 12, 1197, 6)
#   0.283175 => (60, 15, 10000, 20)
#   0.261614 => (76, 12, 5067, 6)
#   0.263163 => (40, 12, 4982, 6)
#   0.246846 => (40, 12, 4994, 6)
#   0.254292 => (60, 12, 5067, 6)
#   0.258944 => (64, 11, 1994, 6)
#   0.273945 => (40, 15, 10000, 20)
#   0.264005 => (40, 12, 1197, 7)
#   0.264002 => (40, 12, 4940, 7)
#   0.256894 => (47, 14, 7731, 1)
#   0.26486  => (76, 12, 5067, 7)
#   0.264587 => (20, 20, 1000, 10)
#   0.286819 => (47, 14, 8316, 16)
#   0.285862 => (46, 17, 16432, 26)
#   0.290088 => (60, 12, 5067, 20)
#   0.256702 => (40, 12, 5067, 7)
#   0.362721 => (99, 3, 8730, 30)
#   0.285059 => (80, 20, 100, 12)
#   0.267928 => (72, 12, 4942, 6)
#   0.264311 => (64, 12, 11095, 5)
#   0.274243 => (40, 15, 5067, 20)
#   0.280937 => (76, 7, 1197, 7)
#   0.258023 => (76, 12, 1197, 7)
#   0.258939 => (76, 12, 4940, 7)
#   0.262463 => (76, 12, 5067, 6)
#   0.275111 => (76, 7, 1197, 7)
#   0.275391 => (40, 12, 10000, 20)
#   0.263803 => (40, 12, 1197, 6)
#   0.363344 => (90, 2, 3082, 13)
#   0.274417 => (76, 7, 1197, 6)
#   0.256015 => (40, 12, 5067, 6)
#   0.262807 => (76, 12, 4940, 6)
#   0.263517 => (76, 12, 1197, 6)
#   0.265764 => (40, 7, 4992, 6)
#   0.266776 => (40, 12, 5067, 7)
#   0.25754  => (40, 15, 5067, 6)
#   0.262863 => (40, 7, 5067, 6)
#   0.297813 => (80, 5, 15000, 15)
#   0.269625 => (76, 7, 5067, 6)
#   0.254191 => (40, 12, 1197, 7)
#   0.305289 => (95, 23, 4404, 23)
