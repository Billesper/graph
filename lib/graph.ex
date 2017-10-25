defmodule Graph do

  alias Graph.Node

  @moduledoc """
  Documentation for Graph, a generic, functional graph library for Elixir.

  The API flexibly supports directed, undirected, weighted, and unweighted graphs.

  Graph implements a generic graph representation on top of Graph.Node nodes, which by default work with :id and :adjacent fields, and additionally have an optional :data field to support arbitrary data types as node data (see Graph.Node for more detail). Thus, Graph.t serves as graph data structure that can serve as the foundation for generic graph algorithms or libraries (e.g. see Graph.Algorithm). Additionaly, it can be easily adapted to specific use cases, for instance by supplying nodes with values of a problem-specific data type to Graph.Node.data.


  The graph state is encapsulated entirely in the "nodes" field, which is a Map.t that maps node IDs to Graph.Node.t structs (see Graph.Node.t for more detail).
  Use binaries for the keys (see: "id" field of Graph.Node) to uniquely identify specify a node in the graph. Almost all functions in Graph involve particular nodes, and thus involve ID parameter(s) which are expected to be of type binary. Wherever possible, the interface enforces that such operations use binary keys via guards, and failing to use them (e.g. by passing integers for ids) will usually result in an undefined function error.

  The only other fields in Graph.t are the boolean flags :directed and :weighted, which as the names imply, determine the graph type. Unless otherwise specified, a new Graph.t struct is a simple graph (i.e. unweighted and undirected). To alternatively create a specific graph type, supply any desired combination of corresponding truth values for :directed and :waited upon creation. Whenever applicable, the API enforces that functions called are appropriate for the specified type of graph, e.g. you cannot add a directed edge to a Graph.t struct that has :directed set to false.

  Note on representation of directed vs. undirected graphs: 
  The implementation internally represents all edges as unidirectional, regardless of whether the graph is directed or not. When adding an edge to a Graph with :directed == false, the module adds . However, when checking of an undirected 
  """  

  @type nodeset(struct) :: Map.t(binary, Node.t(struct))
  @type nodeset :: Map.t(binary, Node.t)
  defstruct nodes: nil, directed: false, weighted: false

  @type t(struct) :: %Graph{nodes: nodeset(struct)}
  @type t :: %Graph{nodes: nodeset}

  #~~~CREATION~~~
  @doc """
  """
  def new(), do: %Graph{nodes: %{}}

  @doc """
  Creates a new graph struct from "nodeset", a MapSet of Node structs
  """
  def new(nodeset) do
    nodesMap = Enum.reduce(nodeset, Map.new, fn (node, acc) ->
      Map.put(acc, node.id, node)
    end)
    %Graph{nodes: nodesMap}
  end
  
  #~~~ADDING AND REMOVING NODES~~~
  @doc """
  Adds a node to the graph
  Requires that a node with that id does not already exist

  If the graph already has a node with the id passed to add_node, add_node prints an error and returns the unaltered graph.
  """
  @spec add_node(Graph.t, Node.t) :: Graph.t
  def add_node(graph = %Graph{nodes: nodes}, node = %Node{id: id}) when is_binary(id) do
    if not has_node?(graph, id) do
      %Graph{graph | nodes: Map.put(nodes, id, node)}
    else
      IO.puts "Error: node not added."
      IO.puts "A node with id: <#{id}> already exists"
      graph
    end
  end

  @doc """
  """
  @spec remove_node(Graph.t, binary) :: Graph.t
  def remove_node(graph = %Graph{directed: isDirected, nodes: nodes}, nodeID) do
       
    if has_node?(graph, nodeID) do

      if not isDirected do
        #first retrieve any adj nodes and delete their edges with the node that will be removed
        adjIDs = Graph.get_node(graph, nodeID).adjacent
        Enum.each(adjIDs, fn (adj) ->
          remove_edge(graph, nodeID, adj)
        end)
      end
      
      #remove the node itself from the graph   
      %Graph{graph | nodes: Map.delete(nodes, nodeID)}
    end
    
  end

  #~~~ADDING AND REMOVING EDGES~~~  
  @doc """
  Public interface for adding an edge

  To succesfully add an edge, add_edge requires that both nodes already exist in the graph.

  Otherwise, prints an error message
  """
  @spec add_edge(Graph.t, binary, binary) :: Graph.t  
  def add_edge(graph = %Graph{}, sourceNodeID, destNodeID)
  when is_binary(sourceNodeID) and is_binary(destNodeID) do
    if has_node?(graph, sourceNodeID) and has_node?(graph, destNodeID) do
      _add_edge(graph, sourceNodeID, destNodeID)
    else
      #print error to user specifying which of the supplied nodes are not in the graph
      print_add_edge_error(graph, sourceNodeID, destNodeID)
    end    
  end


  # Adds an edge of the specified type to the graph when 
  # both nodes are present.
  @spec _add_edge(Graph.t, binary, binary) :: Graph.t  
  defp _add_edge(graph = %Graph{directed: isDirected}, sourceNodeID, destNodeID) do
    #helper closure to add the edge to Graph.nodes map
    register_edge = fn (g, source, dest) ->
      
      updatedNode = Node.add_adjacent(get_node(g, source), dest)
      set_node(g, updatedNode)
    end

    graph = register_edge.(graph, sourceNodeID, destNodeID)

    #also add edge in the other direction if the graph is undirected
    if not isDirected do
      register_edge.(graph, destNodeID, sourceNodeID)
    else
      graph
    end
  end
    

  # Prints proper error ouput when at least one of the nodes in the 
  # proposed edge does not yet exist in the graph.
 
  defp print_add_edge_error(graph, sourceID, destID) do
    IO.puts "Error: Cannot add edge."
        
    print_node_dne_error(graph, sourceID)
    print_node_dne_error(graph, destID)
  end

  defp print_node_dne_error(g = %Graph{}, id) do
      if !has_node?(g, id), do: IO.puts("Node with id: <#{id}> does not exist in the graph.")    
  end

  @doc """
  Returns graph with the specified directed edge removed.

  If the edge is not present, prints an error message, and returns nil.
  """
  def remove_edge(g = %Graph{directed: true}, source, dest) do
    remove_dir_edge(g, source, dest)
  end
  @doc """
  Returns graph with the specified undirected edge removed.

  If the edge is not present, prints an error message, and returns nil.
  """
  def remove_edge(g = %Graph{directed: false}, source, dest) do
    g_modified = remove_dir_edge(g, source, dest)
    if g_modified == nil do
      nil
    else
      remove_dir_edge(g_modified, dest, source)
    end
  end

  #Removes the edge if present and returns the updated graph
  #Note that Node.remove_adjacent/2 prints the appropriate error message if necessary.
  defp remove_dir_edge(g = %Graph{}, source, dest) do
    if !get_node(g, source) || !get_node(g, dest) do
      nil
    else
      updatedSourceNode = Graph.get_node(g, source) |> Node.remove_adjacent(dest)
      if updatedSourceNode == nil, do: nil, else: set_node(g, updatedSourceNode)
    end
  end

  #~~~OPERATIONS ON NODES~~~
  @doc """
  Returns a map of ids to graph nodes.
  """
  def get_nodes(%Graph{nodes: nodes}), do: nodes

  def num_nodes(%Graph{nodes: nodes}), do: map_size(nodes)

  def get_node(%Graph{nodes: nodes}, nodeID), do: nodes[nodeID]

  def set_node(graph = %Graph{nodes: nodes}, node = %Node{}) do
      %Graph{graph | nodes: Map.put(nodes, Node.get_id(node), node)}    
  end

  @doc """
  Returns true i.f.f. graph has a node with id nodeID
  """
  @spec has_node?(Graph.t, binary) :: boolean
  def has_node?(%Graph{nodes: nodes}, nodeID), do: Map.has_key?(nodes, nodeID)

end
