# Graph

  Graph is an idiomatic Elixir library for graph representation and algorithms.

## Documentation

  To view the HTML documentation (generated via [ExDoc](https://github.com/elixir-lang/ex_doc)), open:
  [graph/doc/index.html](https://github.com/billesper/graph/doc/index.html).

## Installation

   Make sure the latest versions of Elixir and Erlang are installed on your machine (for detailed
   instructions, see https://elixir-lang.org/install.html).

   Run `git clone` to download the repository.

   From the command line, navigate to the project's top-level directory. Call `mix test` to run the
   test suite,
   or `iex -S mix` to work with the project interactively, etc.

   To add the library to your own Elixir project, add the project or the implementation
   files in /lib to your project directory, and import any modules as desired.
   
## Simple Example Usage 

   #### 1) Graph: functional data structure for graph representation
   ```
   iex> graph = Graph.new()
   %Graph{directed: false, nodes: %{}, weighted: false}
   iex> nyc = %Node{id: "0", data: "New York", adjacent: MapSet.new()}
   iex> sf = %Node{id: "1", data: "San Francisco", adjacent: MapSet.new()}
   iex> graph = Graph.add_node(graph, nyc)
   iex> graph = Graph.add_node(graph, sf)
   iex> graph = Graph.add_edge(graph, nyc, sf)
   %Graph{directed: false, weighted: false, nodes: %{
   "0" => %Node{id: "0", data: "New York", adjacent: #MapSet<["1"]>}
   "1" => %Node{id: "1", data: "San Francisco", adjacent: #MapSet<["0"]>}}
   } 
   ```
   
   #### 2) Graph.Algorithm - collection of graph algorithms
   ```
   # BFS/DFS from some source node
   iex> sourceNodeID = "3"
   iex> goalNodeID = "5"
   # suppose node with goalNodeID is reachable from node with sourceNodeID on graph
   iex> Graph.Algorithm.dfs_source?(graph, sourceNodeID, goalNodeID)
   true
   iex> Graph.Algorithm.bfs_source(graph, sourceNodeID, goalNodeID)
   true
   # if graph is undirected and the shortest path from node "3" to "5" is 4 edges:
   iex> Graph.Algorithm.bfs_source(graph, sourceNodeID, goalNodeID, report_dist: true)
   {true, 4}

   # topological sorting
   # suppose baking_dag is an acyclic directed graph representing steps in a cake baking process,
   iex> Graph.Algorithm.topological_sort(baking_dag)
   ["get bowl", "get ingredients", "get pan", "mix ingredients in bowl",
   "add mixed ingredients to pan", "heat oven", "bake cake"]
   ```
   
## Future TODO:
   * Expand library of algorithms
   * Add more support for weighted graphs
   * Add a [behaviour](https://elixir-lang.org/getting-started/typespecs-and-behaviours.html) for classical AI algorithms
    on graphs, such as A*, bidrectional search, and others.
   
