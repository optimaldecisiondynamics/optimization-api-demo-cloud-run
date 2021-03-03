dog_maximizer_post_processor <- function() {
  ########################################## SETUP #######################################################################
  
  # Read in node set, arc set, and solution
  
  nodes <- read.csv("location_info.csv", header = TRUE, sep = ",", na.strings = "")
  
  arcs <- read.csv("route_info.csv", header = TRUE, sep = ",", na.strings = "")
  
  woof_solution <- read.csv("pet_lots_of_dogs.csv", header = TRUE, sep = ",", na.strings = "")
  
  ################################ PATH PREP ########################################################################
  
  # Derive path by following selected arcs, starting from the source
  woof_solution_selected_arcs <- filter(woof_solution, selected_in_path == 1)
  
  # We know the path starts from the source, and that any node in the path exists exactly once
  # Find the source node
  node_type_mapper <- select(nodes, location, node_type)
  
  woof_origin_node_types <- merge(woof_solution_selected_arcs, node_type_mapper,
                                  by.x = c("origin"),
                                  by.y = c("location"))
  
  # first arc starts with the source node
  first_arc_in_path <- filter(woof_origin_node_types,
                              node_type == "source")
  
  other_arcs <- filter(woof_origin_node_types,
                       node_type != "source")
  
  ################################### DERIVE PATH ######################################################################
  
  # Traverse the selected arcs to derive the path, in order
  # Start with the arc containing the source node
  
  # Output a list detailing the path
  # Initialize, then populate
  path_to_pet_dogs <- c()
  
  # Source node goes first, then the destination node in the first arc
  path_to_pet_dogs <- c(first_arc_in_path$origin[1], first_arc_in_path$destination[1])
  
  remaining_arcs <- other_arcs
  
  while(nrow(remaining_arcs) != 0) {
    
    # Find the last element in the path_to_pet_dogs list
    # aka the location we're currently at on our path
    current_node <- tail(path_to_pet_dogs, n = 1)
    
    # Find an arc that has an origin node == current node
    next_arc <- filter(remaining_arcs, origin == current_node)
    
    # The destination node of next_arc is the next node in our path
    path_to_pet_dogs <- c(path_to_pet_dogs, next_arc$destination[1])
    
    # Now that this arc has been added we can remove it from remaining_arcs
    remaining_arcs <- filter(remaining_arcs, origin != current_node)
    
  }
  
  # path_to_pet_dogs is our dog-maximizing path!
  
  ################################## OUTPUT FOR OUR DOG PETTING USER ####################################################
  
  
  # make this a dataframe
  dog_maximizing_path <- data.frame(location = path_to_pet_dogs)
  
  # Map back the number of dogs we'll pet at each node
  dog_maximizing_path <- merge(dog_maximizing_path, nodes,
                               by.x = c("location"),
                               by.y = c("location"))
  
  dog_maximizing_path <- select(dog_maximizing_path, 
                                location, dogs)
  
  # write to a CSV using the server's file system
  write.csv(dog_maximizing_path, file = "dog_maximizing_path.csv", row.names = FALSE)
  
  # Also output the total travel time of the path
  woof_solution_selected_arcs <- select(woof_solution_selected_arcs, -selected_in_path)
  
  time_per_arc <- merge(woof_solution_selected_arcs, arcs,
                        by.x = c("origin", "destination"),
                        by.y = c("origin", "destination"))
  
  # total time
  total_travel_time <- sum(time_per_arc$travel_time)
  
  total_travel_time_df <- data.frame(travel_time = total_travel_time)
  
  # write to a CSV using the server's file system
  write.csv(total_travel_time_df, file = "total_travel_time.csv", row.names = FALSE)
}