############################ SETUP ########################################
from pyomo.environ import *

import os

import pandas as pd

from pathlib import Path

model = AbstractModel()

############################# SETS #########################################

model.N = Set()

model.A = Set(within = model.N * model.N)

################################ PARAMETERS ###################################

# Time limit
model.time_limit = Param()

# Travel time: the time to traverse an arc
model.travel_time = Param(model.A)

# Node type: source, sink, intermediary
model.node_type = Param(model.N)

# Expected number of dogs to pet at each location
model.dogs = Param(model.N)

########################## DECISION VARIABLES #################################

model.route = Var(model.A, within = Binary)

############################### OBJECTIVE FUNCTION ##############################

def dogs_pet_rule(model):
    return sum(model.dogs[j] * model.route[i,j] for (i,j) in model.A if model.node_type[j] == 'intermediary')
model.dogs_pet = Objective(rule = dogs_pet_rule, sense = maximize)

########################### CONSTRAINTS ########################################

# Arc selection along the path
def path_constraints_rule(model, i):
    if model.node_type[i] == 'source':
        return sum(model.route[i,j] for j in model.N if (i,j) in model.A) - sum(model.route[j,i] for j in model.N if (j,i) in model.A) == 1
    elif model.node_type[i] == 'sink':
        return sum(model.route[i,j] for j in model.N if (i,j) in model.A) - sum(model.route[j,i] for j in model.N if (j,i) in model.A) == -1
    else:
        return sum(model.route[i,j] for j in model.N if (i,j) in model.A) - sum(model.route[j,i] for j in model.N if (j,i) in model.A) == 0
model.path_constraints = Constraint(model.N, rule = path_constraints_rule)

# Time limit: Our jaunt can't exceed the time we have available
def jaunt_time_limit_rule(model):
    return sum(model.travel_time[i,j] * model.route[i,j] for (i,j) in model.A) <= model.time_limit
model.jaunt_time_limit = Constraint(rule = jaunt_time_limit_rule)

#################### POPULATE WITH DATA AND CREATE MODEL INSTANCE ###################

# Find problem instance data via directory
wd = os.path.abspath('')

problem_directory = wd + '/'

# Read in data to create problem instance
data = DataPortal()

data.load(filename = problem_directory + 'total_time.csv', param = model.time_limit)

data.load(filename = problem_directory + 'location_info.csv',
select = ('location', 'node_type', 'dogs'), param = (model.node_type, model.dogs),
index = model.N)

data.load(filename = problem_directory + 'route_info.csv',
select = ('origin', 'destination', 'travel_time'), param = model.travel_time,
index = model.A)

instance = model.create_instance(data, report_timing=True)

######################### SOLVE ############################################

solver = SolverFactory('cbc')

# Set solver options, such as the number of threads to use and timeout
solver.options['threads'] = 2

solver.options['seconds'] = 60

# Now solve!
results = solver.solve(instance, tee = True)

################## WRITE SOLUTION TO CSV ######################################

with open(Path(problem_directory + 'pet_lots_of_dogs.csv'), 'w') as f:
    f.write('origin,destination,selected_in_path\n')
    for (i,j) in instance.A:
        f.write('%s,%s,%s\n' % (i,j, instance.route[i,j].value))
