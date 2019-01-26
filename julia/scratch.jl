# x = -3.0:0.1:3.0
# f(x) = x^2
# y = f.(x)

using Pkg
using CSV
using DataFrames
using StatsBase
using Statistics
using ASTInterpreter2
using DebuggerFramework

const global dataframe = open("/home/ubuntu/data/kc_house_data/kc_house_data.csv") |> CSV.File |> DataFrame

const global label = :price
const global threashold = 2500
const global max_branches = 10

function partition(feature_values)
    x = feature_values |> countmap |>  cm -> filter((x -> x.second > 3), cm) |> collect |> size |> first
  if x <= max_branches
    feature_values |> unique .|> (x -> (first = x, second = x))
  else
    acc = []
    step = feature_values |> std
    max = feature_values |> maximum
    fst = feature_values |> minimum
    snd = fst + step
    while snd < max
      # println(" fst: $fst ,  snd: $snd ,  max: $max ,  step: $step , ")
      proposed = (first = fst, second = snd)
      if (filter(x -> inpartition(proposed, x), feature_values) |> size |> first) > 0
        push!(acc, proposed)
      end
      fst = snd
      snd = snd + step
    end
    acc
  end
end

function inpartition(tup, val)
  tup.first == val || (val >= tup.first && val < tup.second)
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

function build_tree(df)
  if (std(df[label]) < threashold) || (df |> names |> size |> first) < 2 || (df[label] |> size |> first) < 12
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

function treewalk(item, branch::Array, value=0)
  branch
end

function treewalk(item, branch::Dict, value=0)
  println(item[:id])
  ks = (branch |> keys |> collect)
  if (ks |> size |> first) < 1
    (item, branch, value)
  elseif (ks |> size |> first) == 1 && (ks |> first |> typeof) == Symbol
    ky = ks |> first
    println(ky)
    new_branch = branch[ky]
    treewalk(item, new_branch, (item[ky] |> first))
  else
    println("+++++++++++++++")
    println(value)
    println(ks)
    println("---------------")
    ky = filter(x -> inpartition(x, value), ks) |> first
    new_branch = branch[ky]
    treewalk(item, new_branch)
  end
end


dc = copy(dataframe)
for ing in [:id, :sqft_lot15, :sqft_living15, :date]
  deletecols!(dataframe, ing)
end
tree = build_tree(dataframe)
eachrow(dc) .|> (x -> treewalk(x, tree)) .|> println

df = filter(x -> x[:id] == 1736800520, dc)
# rng = treewalk(df, tree)



