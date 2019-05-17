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
  if (feature_values |> unique |> length) > 15
    large_partition(feature_values)
  else
    small_partition(feature_values)
  end
end

function inpartition(tup, val::Union{String, Char})
  (tup.first == val)
end

function inpartition(tup, val)
  (val >= tup.first && val < tup.second)
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

function small_difference(df, threashold)
  min = (df[label] |> minimum)
  max = (df[label] |> maximum)
  (max - min) < threashold
end

function build_tree(df, threashold)
  if (df |> names |> size |> first) < 2 || small_difference(df, threashold)
    df[label]
  else
    feature = df |> gainz |> next_feature
    new_nodes = Dict()
    for v in partition(df[feature])
      subframe = filter(x -> inpartition(v, x[feature]), df)
      deletecols!(subframe, feature)
      subtree = build_tree(subframe, threashold)
      new_nodes[v] = subtree
    end
    Dict(feature => new_nodes)
  end
end

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

function many_tree_slices(full_set, slices)
  @assert slices > 1

  acc = []
  max = size(full_set, 1)
  @assert max > 0
  @assert typeof(max) == Int64

  slice_size = trunc(Int64, ceil(max / slices))
  @assert slice_size > 0
  @assert typeof(slice_size) == Int64
  lower = 1
  upper = slice_size * 2

  while lower < max
    subset = full_set[lower:upper, :]
    tree = build_tree(subset, 1000)
    mn = subset[label] |> minimum
    mx = subset[label] |> maximum
    push!(acc, (tree = tree, min = mn, max = mx))
    lower = lower + slice_size
    upper = upper + slice_size
    if upper > max
      upper = max
    end
    @assert upper <= max
  end
  acc
end

function random_tree_selection(full_set, probability, number)
  acc = []
  for n in number
    tmp = filter(row -> (random(1:100) < probability), full_set)
    push!(build_tree(tmp, 1000), acc)
  end
  acc
end

test_set = copy(dataframe[1:292, :])
train_set = copy(dataframe[293:1460, :])

# tree = build_tree(train_set, 1000)
# global myerr = []
# for i in 1:size(test_set, 1)
#   item = test_set[i, :]
#   predict = treewalk(item, tree)
#   err = abs(log(predict) - log(item[label]))
#   push!(myerr, err)
# end
# println(sqrt(mean(myerr.^2.)))

trees = random_tree_selection(train_set, 21);

global myerr = []
for i in 1:size(test_set, 1)
  item = test_set[i, :]
  predictions = []
  for t in trees
    try
      p = treewalk(item, t)
    catch e
      println("caught an error: $e")
    end
    bar = ! @isdefined p
    if bar # || p == t.min || p == t.max
      #nop
    else
      push!(predictions, p)
    end
  end
  predict = mean(predictions)
  err = abs(log(predict) - log(item[label]))
  # if err > 100000
  #   println(sort(predictions))
  #   println(predict)
  #   println(item[label])
  # end
  push!(myerr, err)
end


predict = treewalk()
println(sqrt(mean(myerr.^2.)))

#unsorted single tree
# julia> println(mean(myerr))
# 184383.37709441825

# julia> println(sqrt(mean(myerr.^2.)))
# 334189.8279692254


# unsorted & sliced
# julia> println(mean(myerr))
# 151868.14472280702

# julia> println(sqrt(mean(myerr.^2.)))
# 280462.39544090594


# sorted & sliced
# julia> println(mean(myerr))
# 235164.47230174634

# julia> println(sqrt(mean(myerr.^2.)))
# 385158.98424631305


# unsorted & overlapping slices
# julia> println(mean(myerr))
# 147712.1182026513

# julia> println(sqrt(mean(myerr.^2.)))
# 264368.5619372746


# sorted & overlapping slices
# julia> println(mean(myerr))
# 236879.06318660572

# julia> println(sqrt(mean(myerr.^2.)))
# 379433.6094573489

