defmodule Graph do

  alias Graph.Node

  @moduledoc """
  Documentation for Graph

  This module implements a generic graph data structure, which is used to support 
  the algorithms implemented in Graph.Algorithm. However, it can also serve as a general 
  API for graph representation.

  Both directed and undirected graphs are supported, and in the future, 
  functionality specific to weighted graphs will be added.

  Struct fields:

  * The graph state (in terms of nodes and edges) is encapsulated entirely in the 
  "nodes" field, which is a Map.t that maps node IDs to Graph.Node.t structs 
  (see Graph.Node.t for more detail).

  * The only other fields in Graph.t are the boolean flags :directed and :weighted, which as the names imply, 
  determine the type of graph representation. Unless otherwise specified, a new Graph.t struct is a simple graph 
  (i.e. unweighted and undirected) [note: the current implementation does not prevent a client from adding loops]. 

  To alternatively create a graph of a different type, supply any desired combination of corresponding truth values 
  for :directed and :weighted upon creation. Whenever applicable, the API enforces that functions called are 
  well-defined for the type of graph passed to them as an argument.
  e.g. you cannot add a directed edge to a Graph.t struct that has :directed set to false.

  """

  # General implementation notes:
  
  # Note on the representation of directed vs. undirected graphs: 
  # The implementation internally represents all edges as unidirectional,
  # regardless of whether the graph is directed or not. 
  # For undirected graphs, adding/removing edges adds/removes
  # the internal "directed" edges in both directions
  
  # TODO:
  # *Update module to support weighted edges / graphs
  # add further functionality specific to other types of graphs beyond undirected/unweighted
  
  @type id :: binary | integer
  @type nodesmap(struct) :: Map.t(id, Node.t(struct))
  @type nodesmap :: Map.t(id, Node.t)

  # NOTE: weighted field is present here, but currently this module and
  # others in the library do not yet support functionality specific to weighted graphs
  defstruct nodes: nil, directed: false, weighted: false

  @type t(struct) :: %Graph{nodes: nodesmap(struct)}
  @type t :: %Graph{nodes: nodesmap}

  #~~~CREATION~~~
  @doc """
  Creates an unweighted, undirected graph struct, with an empty nodes map.
  """
  def new(), do: %Graph{nodes: %{}}

  @doc """
  Creates a new graph struct for an unweighted/undirected graph from "nodeset", 
  an Enum of Node structs
  """
  def new(nodeset) do
    nodesMap = Enum.reduce(nodeset, Map.new, fn (node, acc) ->
      Map.put(acc, node.id, node)
    end)
    %Graph{nodes: nodesMap}
  end
  
  #~~~ADDING AND REMOVING NODES~~~
  @doc """
  Adds a node to the graph, as long as a node with that id does not already exist

  If the graph already has a node with the id passed to add_node, 
  add_node prints an error and returns the unaltered graph.
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
  Removes the specified node from the graph, if it exists.
  if the graph is undirected, also removes any edges connected to it

  Returns the updated graph if the node exists, otherwise, nil.
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
  Adds an edge to the graph

  To succesfully add an edge, add_edge requires that both nodes already exist in the graph.

  When the inputs are valid, returns the updated graph

  Otherwise, prints an error message
  """
  def add_edge(graph = %Graph{}, sourceNodeID, destNodeID) do
    if has_node?(graph, sourceNodeID) and has_node?(graph, destNodeID) do
      _add_edge(graph, sourceNodeID, destNodeID)
    else
      #print error to user specifying which of the supplied nodes are not in the graph
      print_add_edge_error(graph, sourceNodeID, destNodeID)
    end    
  end

  # Adds an edge of the specified type to the graph when 
  # both nodes are present.
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

  # Prints node DNE error output for a node when it doesn't exist 
  defp print_node_dne_error(g = %Graph{}, id) do
      if !has_node?(g, id), do: IO.puts("Node with id: <#{id}> does not exist in the graph.")    
  end

  @doc """
  Returns graph with the specified directed edge removed

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

  # Removes the edge if present and returns the updated graph
  # Note that Node.remove_adjacent/2 prints the appropriate error message if necessary.
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
  Returns a map of ids to graph nodes
  """
  def get_nodes(%Graph{nodes: nodes}), do: nodes

  @doc """
  Returns the number of nodes in the graph
  """
  def num_nodes(%Graph{nodes: nodes}), do: map_size(nodes)

  @doc """
  Returns the node struct for the node with the specified id, if it exists,
  else nil
  """
  def get_node(%Graph{nodes: nodes}, nodeID), do: nodes[nodeID]

  @doc """
  Sets the key node.id in the graph's nodes map to the given node
  """
  def set_node(graph = %Graph{nodes: nodes}, node = %Node{}) do
   id = Node.get_id(node)
   %Graph{graph | nodes: Map.put(nodes, id, node)}   
  end

  @doc """
  Returns true i.f.f. graph has a node with id nodeID
  """
  def has_node?(%Graph{nodes: nodes}, nodeID), do: Map.has_key?(nodes, nodeID)

end
