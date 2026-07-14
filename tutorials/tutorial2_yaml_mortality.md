# Talos Tutorial 2: Understanding YAML, Lua, and Adding Mortality

## Overview

In this tutorial, we'll dive deeper into YAML and Lua. You'll learn how YAML rules work, how to add a mortality model to your simulation, and how to create meaningful statistics to track population changes.

## What You'll Learn

By the end of this tutorial, you'll be able to:
- Understand YAML formatting rules
- Write a mortality model using Lua
- Create age distribution statistics
- Understand Lua in plain English

## Prerequisites

- Completion of Tutorial 1 (or equivalent knowledge)
- The `population.csv` file from Tutorial 1
- A text editor

---

## Part 1: Understanding YAML Rules

In Tutorial 1, we copied a YAML configuration and it just worked. Now let's understand **why** it worked and what the rules are.

### Rule 1: YAML Uses Spaces, Not Tabs

This is the most common mistake! YAML uses **spaces** for indentation, **never tabs**.

```yaml
# ✅ CORRECT - using spaces
simulation:
  iterations: 5
  population_file: "population.csv"

# ❌ WRONG - using tabs (invisible but will cause errors)
simulation:
	iterations: 5
	population_file: "population.csv"
```

**Why does this matter?** YAML reads indentation to understand what belongs to what. If you use tabs, YAML gets confused and throws an error.

### Rule 2: Multi-line Strings Need the Pipe (`|`)

In Tutorial 1, we used this in our model:

```yaml
script: |
  function transition(population, params)
    for _, person in ipairs(population) do
      if person.alive == true then
        person.age = person.age + 1
      end
    end
    return population
  end
```

The pipe (`|`) tells YAML: "Everything that follows, indented, is a single string value." This allows us to write clean, readable Lua scripts that span multiple lines.

**What happens without the pipe?**

```yaml
# ❌ WRONG - YAML sees three separate values
script: function transition(population, params)
  for _, person in ipairs(population) do
    if person.alive == true then
      person.age = person.age + 1
    end
  end
  return population
end
```

YAML would see this as multiple separate lines and throw an error because it expects a single value after the colon.

**Important:** The content after the pipe must be indented:

```yaml
# ✅ CORRECT - content is indented
script: |
  function transition(population, params)
    for _, person in ipairs(population) do
      if person.alive == true then
        person.age = person.age + 1
      end
    end
    return population
  end

# ❌ WRONG - content is not indented
script: |
function transition(population, params)
  for _, person in ipairs(population) do
    if person.alive == true then
      person.age = person.age + 1
    end
  end
  return population
end
```

### Rule 3: Column Names Must Match Your CSV Exactly

**This is the most important rule for Talos!** The column names you use in your Lua scripts must exactly match the column names in your CSV file.

```csv
# CSV column names
person_id,age,sex,area,alive
```

```lua
-- ✅ CORRECT - matches CSV
if person.alive == true then
  person.age = person.age + 1
end

-- ❌ WRONG - 'Alive' doesn't match 'alive' in CSV
if person.Alive == true then
  person.Age = person.Age + 1
end
```

**Why does this matter?** Talos loads your CSV and creates a data structure with the exact column names from your CSV. If you use `Alive` but your CSV has `alive`, Talos won't find the column.

### Quick YAML Reference

| What you want | How to write it |
|---------------|-----------------|
| A key-value pair | `key: value` |
| A multi-line string | `key: |`<br>`  line 1`<br>`  line 2` |
| A list | `- item 1`<br>`- item 2` |
| A comment | `# This is a comment` |
| Indentation | Use 2 spaces (or 4, but be consistent) |

---

## Part 2: Understanding Lua (In Plain English)

Before we write more Lua, let's understand what Lua does in plain English.

**Lua is a simple scripting language that reads like English.**

Think of your population as a list of people, where each person has properties:

| person_id | age | sex | area | alive |
|-----------|-----|-----|------|-------|
| 1 | 25 | F | 1 | true |
| 2 | 30 | M | 1 | true |
| 3 | 45 | F | 1 | true |
| ... | ... | ... | ... | ... |

Lua lets you:

- **Loop through people**: `for _, person in ipairs(population) do`
- **Check conditions**: `if person.alive == true then`
- **Make changes**: `person.age = person.age + 1`
- **Count things**: `#population`
- **Return results**: `return population`

That's it! You don't need to know anything else about programming.

### The Lua You'll Use in This Tutorial

| Lua Concept | What it does | Example | Plain English |
|-------------|--------------|---------|---------------|
| `function` | Define a function | `function transition(population, params)` | "Here's a model that runs each year" |
| `for` | Loop through a list | `for _, person in ipairs(population) do` | "For each person in the population..." |
| `if` | Check a condition | `if person.alive == true then` | "If they are alive..." |
| `==` | Compare values | `person.alive == true` | "Is alive equal to true?" |
| `=` | Assign a value | `person.age = person.age + 1` | "Set age to age plus 1" |
| `return` | Return a value | `return population` | "Send back the updated population" |
| `#` | Count items | `#population` | "How many people are there?" |
| `{}` | Create a table | `{ total = #population }` | "Create a result with total count" |

---

## Part 3: Adding a Mortality Model

Now let's add a mortality model to our simulation. This will make our model more realistic by allowing people to die.

### What We Want to Do

**In plain English:** "Each year, check every person. If they are alive and under 30, there's a 0.1% chance they die. If they are alive and 30 or over, there's a 5% chance they die. If they die, mark them as dead."

### The Mortality Model in YAML with Lua

Here's the mortality model as it appears in your `config.yaml`:

```yaml
# Model 2: Mortality (runs second)
- name: "mortality"
  type: "lua_model"
  priority: 2
  enabled: true
  description: "Age-specific mortality: 0.1% for under 30, 5% for 30+"
  parameters:
    script: |
      function transition(population, params)
        for _, person in ipairs(population) do
          if person.alive == true then
            local age = person.age
            local prob = 0
            
            if age < 30 then
              prob = 0.001  -- 0.1% chance
            else
              prob = 0.05   -- 5% chance
            end
            
            if math.random() < prob then
              person.alive = false
            end
          end
        end
        return population
      end
```

**First, in plain English:** "Go through everyone in the population. For each person who is alive, check their age. If they are under 30, flip a coin with a 0.1% chance of coming up heads. If heads, mark them as dead. If they are 30 or over, flip a coin with a 5% chance of coming up heads. If heads, mark them as dead."

**Let's break down what each part does:**

| Part | What it does | In plain English |
|------|--------------|------------------|
| `- name: "mortality"` | Names the model | "This model is called 'mortality'" |
| `type: "lua_model"` | Tells Talos it's a Lua script | "This is a Lua model" |
| `priority: 2` | Sets execution order | "Run this after priority 1 models" |
| `enabled: true` | Activates the model | "This model is turned on" |
| `script: |` | Starts the Lua code | "Here comes the Lua script..." |
| `function transition(population, params)` | Defines the model | "This is the model that runs each year" |
| `for _, person in ipairs(population) do` | Loops through people | "For each person in the population..." |
| `if person.alive == true then` | Checks if alive | "...if they are alive..." |
| `local age = person.age` | Gets their age | "...get their age..." |
| `if age < 30 then` | Checks age group | "...if they're under 30..." |
| `prob = 0.001` | Sets probability | "...they have a 0.1% chance of dying" |
| `else` | Otherwise | "...otherwise (they're 30 or over)..." |
| `prob = 0.05` | Sets probability | "...they have a 5% chance of dying" |
| `if math.random() < prob then` | Rolls the dice | "...roll a random number..." |
| `person.alive = false` | Marks as dead | "...if it's less than the probability, mark them as dead" |
| `return population` | Returns updated population | "Send back the updated population" |

**What is `math.random()`?** In Lua, `math.random()` generates a random number between 0 and 1. So `math.random() < 0.001` means "there's a 0.1% chance this is true" (like flipping a weighted coin).

### Creating the Full Configuration

Here's our complete configuration with both aging and mortality:

```yaml
# config_aging_mortality.yaml
# Aging and mortality model

simulation:
  iterations: 5
  population_file: "population.csv"
  output_file: "population_aged_mortality.csv"
  random_seed: 42
  verbose: true
  id_column: "person_id"

models:
  # Model 1: Age increment (runs first)
  - name: "age_increment"
    type: "lua_model"
    priority: 1
    enabled: true
    description: "Increment everyone's age by 1 year"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              person.age = person.age + 1
            end
          end
          return population
        end

  # Model 2: Mortality (runs second)
  - name: "mortality"
    type: "lua_model"
    priority: 2
    enabled: true
    description: "Age-specific mortality: 0.1% for under 30, 5% for 30+"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              local age = person.age
              local prob = 0
              
              if age < 30 then
                prob = 0.001  -- 0.1% chance
              else
                prob = 0.05   -- 5% chance
              end
              
              if math.random() < prob then
                person.alive = false
              end
            end
          end
          return population
        end

statistics:
  - name: "population_total"
    description: "Total population (alive and dead)"
    script: |
      function statistic(population)
        return { total = #population }
      end
  
  - name: "population_status"
    description: "Alive and dead counts"
    script: |
      function statistic(population)
        local alive = 0
        local dead = 0
        for _, person in ipairs(population) do
          if person.alive == true then
            alive = alive + 1
          else
            dead = dead + 1
          end
        end
        return { alive = alive, dead = dead }
      end
```

### Why Priority Matters

Notice we have **two models** now:
- **Priority 1**: Age increment (runs first)
- **Priority 2**: Mortality (runs second)

**Why this order?** We want people to age first, then we check if they die at their new age. Someone who turns 30 this year should now face the higher 30+ mortality rate.

### Running the Simulation

Save the configuration as `config_aging_mortality.yaml` and run it:

```bash
./talos config_aging_mortality.yaml
```

### Expected Output

```
2024/01/15 10:00:00 ═══ Talos-Pure: Migration Microsimulation ═══
2024/01/15 10:00:00 Iterations: 5
...
2024/01/15 10:00:00 ═══ Iteration 1/5 ═══
2024/01/15 10:00:00   ▶ age_increment
2024/01/15 10:00:00   ▶ mortality
2024/01/15 10:00:00   📊 Statistics:
2024/01/15 10:00:00     population_total (Total population): total: 10
2024/01/15 10:00:00     population_status (Alive and dead counts): alive: 9, dead: 1

2024/01/15 10:00:00 ═══ Iteration 2/5 ═══
2024/01/15 10:00:00   📊 Statistics:
2024/01/15 10:00:00     population_total (Total population): total: 10
2024/01/15 10:00:00     population_status (Alive and dead counts): alive: 8, dead: 2

...

2024/01/15 10:00:00 ═══ Iteration 5/5 ═══
2024/01/15 10:00:00   📊 Statistics:
2024/01/15 10:00:00     population_total (Total population): total: 10
2024/01/15 10:00:00     population_status (Alive and dead counts): alive: 6, dead: 4

2024/01/15 10:00:00 ═══ Simulation Complete ═══
2024/01/15 10:00:00 Results saved to population_aged_mortality.csv
```

Notice that the total population stays at 10, but some people are now marked as dead. They remain in the dataset but are excluded from future aging and mortality calculations.

---

## Part 4: Adding Age Distribution Statistics

Now let's add statistics to see how the age structure of our population changes over time.

### What We Want to Do

**In plain English:** "Count how many children (under 18), adults (18-64), and elderly (65+) are in the population. Only count people who are alive."

### The Statistics Lua Script

**First, in plain English:** "Count everyone under 18 and call them 'children'. Count everyone between 18 and 64 and call them 'adults'. Count everyone 65 and over and call them 'elderly'. Only include people who are alive."

**The Lua:**

```lua
function statistic(population)
  local children = 0
  local adults = 0
  local elderly = 0
  
  for _, person in ipairs(population) do
    if person.alive == true then
      local age = person.age
      if age < 18 then
        children = children + 1
      elseif age >= 18 and age < 65 then
        adults = adults + 1
      else
        elderly = elderly + 1
      end
    end
  end
  
  return {
    children = children,
    adults = adults,
    elderly = elderly
  }
end
```

**Let's break down what each part does:**

| Part | What it does | In plain English |
|------|--------------|------------------|
| `local children = 0` | Start counter | "Start counting children at zero" |
| `for _, person in ipairs(population) do` | Loop through people | "For each person in the population..." |
| `if person.alive == true then` | Check if alive | "...if they are alive..." |
| `local age = person.age` | Get their age | "...get their age..." |
| `if age < 18 then` | Check if child | "...if they're under 18..." |
| `children = children + 1` | Count them | "...add 1 to the children count" |
| `elseif age >= 18 and age < 65 then` | Check if adult | "...if they're 18-64..." |
| `adults = adults + 1` | Count them | "...add 1 to the adults count" |
| `else` | Otherwise | "...otherwise (65+)..." |
| `elderly = elderly + 1` | Count them | "...add 1 to the elderly count" |
| `return { ... }` | Return results | "Send back the counts" |

### Adding Age Distribution to Our Configuration

Here's our updated configuration with age distribution statistics:

```yaml
# config_aging_mortality_stats.yaml
# Aging, mortality, and age distribution statistics

simulation:
  iterations: 5
  population_file: "population.csv"
  output_file: "population_aged_mortality.csv"
  random_seed: 42
  verbose: true
  id_column: "person_id"

models:
  # Model 1: Age increment
  - name: "age_increment"
    type: "lua_model"
    priority: 1
    enabled: true
    description: "Increment everyone's age by 1 year"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              person.age = person.age + 1
            end
          end
          return population
        end

  # Model 2: Mortality
  - name: "mortality"
    type: "lua_model"
    priority: 2
    enabled: true
    description: "Age-specific mortality: 0.1% for under 30, 5% for 30+"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              local age = person.age
              local prob = 0
              
              if age < 30 then
                prob = 0.001
              else
                prob = 0.05
              end
              
              if math.random() < prob then
                person.alive = false
              end
            end
          end
          return population
        end

statistics:
  - name: "population_status"
    description: "Alive and dead counts"
    script: |
      function statistic(population)
        local alive = 0
        local dead = 0
        for _, person in ipairs(population) do
          if person.alive == true then
            alive = alive + 1
          else
            dead = dead + 1
          end
        end
        return { alive = alive, dead = dead }
      end
  
  - name: "age_distribution"
    description: "Age groups (children, adults, elderly) - alive only"
    script: |
      function statistic(population)
        local children = 0
        local adults = 0
        local elderly = 0
        
        for _, person in ipairs(population) do
          if person.alive == true then
            local age = person.age
            if age < 18 then
              children = children + 1
            elseif age >= 18 and age < 65 then
              adults = adults + 1
            else
              elderly = elderly + 1
            end
          end
        end
        
        return {
          children = children,
          adults = adults,
          elderly = elderly
        }
      end
```

### Running the Updated Simulation

```bash
./talos config_aging_mortality_stats.yaml
```

### Expected Output

```
2024/01/15 10:00:00 ═══ Iteration 1/5 ═══
2024/01/15 10:00:00   📊 Statistics:
2024/01/15 10:00:00     population_status (Alive and dead counts): alive: 9, dead: 1
2024/01/15 10:00:00     age_distribution (Age groups): children: 2, adults: 5, elderly: 2

2024/01/15 10:00:00 ═══ Iteration 5/5 ═══
2024/01/15 10:00:00   📊 Statistics:
2024/01/15 10:00:00     population_status (Alive and dead counts): alive: 6, dead: 4
2024/01/15 10:00:00     age_distribution (Age groups): children: 1, adults: 2, elderly: 3
```

### Understanding the Results

- **Iteration 1**: 9 alive (2 children, 5 adults, 2 elderly)
- **Iteration 5**: 6 alive (1 child, 2 adults, 3 elderly)

As people age and die, the population shrinks and the age structure shifts toward older ages.

---

## Part 5: What You've Accomplished

Congratulations! You've now learned:

1. ✅ **YAML Rules**: 
   - Use spaces, not tabs
   - Use the pipe (`|`) for multi-line strings
   - Column names must match your CSV exactly

2. ✅ **Lua in Plain English**:
   - `function` = "Here's a model"
   - `for` = "For each person"
   - `if` = "If this is true"
   - `math.random()` = "Roll a dice"

3. ✅ **Mortality Model**:
   - Applied age-specific death probabilities
   - Used `math.random()` for probabilistic events
   - Understood priority ordering (age first, then mortality)

4. ✅ **Age Distribution Statistics**:
   - Created age groups (children, adults, elderly)
   - Used `if` and `elseif` for conditional counting
   - Filtered to only count alive people

---

## Part 6: Other Statistics You Can Add

Here are some other statistics you might find useful. These follow the same patterns you've already learned!

### Sex Distribution

**In plain English:** "Count all the females and call them 'females'. Count all the males and call them 'males'. Only count people who are alive."

```lua
function statistic(population)
  local females = 0
  local males = 0
  
  for _, person in ipairs(population) do
    if person.alive == true then
      if person.sex == "F" then
        females = females + 1
      else
        males = males + 1
      end
    end
  end
  
  return { females = females, males = males }
end
```

### Average Age

**In plain English:** "Calculate the average age of everyone who is alive."

```lua
function statistic(population)
  local total_age = 0
  local count = 0
  
  for _, person in ipairs(population) do
    if person.alive == true then
      total_age = total_age + person.age
      count = count + 1
    end
  end
  
  local avg_age = 0
  if count > 0 then
    avg_age = total_age / count
  end
  
  return { avg_age = avg_age }
end
```

### Age Range

**In plain English:** "Find the youngest person and the oldest person who are alive."

```lua
function statistic(population)
  local youngest = nil
  local oldest = nil
  
  for _, person in ipairs(population) do
    if person.alive == true then
      if youngest == nil or person.age < youngest then
        youngest = person.age
      end
      if oldest == nil or person.age > oldest then
        oldest = person.age
      end
    end
  end
  
  return { youngest = youngest or 0, oldest = oldest or 0 }
end
```

### Age Spread (Standard Deviation)

**In plain English:** "Calculate how spread out the ages are. A small number means most people are similar ages. A large number means ages vary a lot. Only include people who are alive."

```lua
function statistic(population)
  -- First pass: calculate average
  local total_age = 0
  local count = 0
  
  for _, person in ipairs(population) do
    if person.alive == true then
      total_age = total_age + person.age
      count = count + 1
    end
  end
  
  local avg_age = 0
  if count > 0 then
    avg_age = total_age / count
  end
  
  -- Second pass: calculate variance
  local sum_sq_diff = 0
  for _, person in ipairs(population) do
    if person.alive == true then
      local diff = person.age - avg_age
      sum_sq_diff = sum_sq_diff + diff * diff
    end
  end
  
  local stddev = 0
  if count > 0 then
    stddev = math.sqrt(sum_sq_diff / count)
  end
  
  return { age_stddev = stddev }
end
```

### Detailed Age Groups (5-year)

**In plain English:** "Count how many people are in each 5-year age group. Only count people who are alive."

```lua
function statistic(population)
  local age_groups = {
    age_0_4 = 0,
    age_5_9 = 0,
    age_10_14 = 0,
    age_15_19 = 0,
    age_20_29 = 0,
    age_30_39 = 0,
    age_40_49 = 0,
    age_50_59 = 0,
    age_60_69 = 0,
    age_70_plus = 0
  }
  
  for _, person in ipairs(population) do
    if person.alive == true then
      local age = person.age
      if age >= 0 and age <= 4 then
        age_groups.age_0_4 = age_groups.age_0_4 + 1
      elseif age >= 5 and age <= 9 then
        age_groups.age_5_9 = age_groups.age_5_9 + 1
      elseif age >= 10 and age <= 14 then
        age_groups.age_10_14 = age_groups.age_10_14 + 1
      elseif age >= 15 and age <= 19 then
        age_groups.age_15_19 = age_groups.age_15_19 + 1
      elseif age >= 20 and age <= 29 then
        age_groups.age_20_29 = age_groups.age_20_29 + 1
      elseif age >= 30 and age <= 39 then
        age_groups.age_30_39 = age_groups.age_30_39 + 1
      elseif age >= 40 and age <= 49 then
        age_groups.age_40_49 = age_groups.age_40_49 + 1
      elseif age >= 50 and age <= 59 then
        age_groups.age_50_59 = age_groups.age_50_59 + 1
      elseif age >= 60 and age <= 69 then
        age_groups.age_60_69 = age_groups.age_60_69 + 1
      else
        age_groups.age_70_plus = age_groups.age_70_plus + 1
      end
    end
  end
  
  return age_groups
end
```

### Deaths by Age Group

**In plain English:** "Count how many dead people are in each age group."

```lua
function statistic(population)
  local deaths_under_30 = 0
  local deaths_30_plus = 0
  
  for _, person in ipairs(population) do
    if person.alive == false then
      if person.age < 30 then
        deaths_under_30 = deaths_under_30 + 1
      else
        deaths_30_plus = deaths_30_plus + 1
      end
    end
  end
  
  return {
    deaths_under_30 = deaths_under_30,
    deaths_30_plus = deaths_30_plus
  }
end
```

### Dependency Ratio

**In plain English:** "For every working-age adult (18-64), how many dependents (under 18 or over 65) are there?"

```lua
function statistic(population)
  local dependents = 0
  local workers = 0
  
  for _, person in ipairs(population) do
    if person.alive == true then
      if person.age < 18 or person.age >= 65 then
        dependents = dependents + 1
      else
        workers = workers + 1
      end
    end
  end
  
  local ratio = 0
  if workers > 0 then
    ratio = (dependents / workers) * 100
  end
  
  return { dependency_ratio = ratio }
end
```

### Full Configuration with All Statistics

Here's a complete configuration with many of these statistics:

```yaml
# config_aging_mortality_full.yaml
# Aging, mortality, and comprehensive statistics

simulation:
  iterations: 5
  population_file: "population.csv"
  output_file: "population_aged_mortality.csv"
  random_seed: 42
  verbose: true
  id_column: "person_id"

models:
  - name: "age_increment"
    type: "lua_model"
    priority: 1
    enabled: true
    description: "Increment everyone's age by 1 year"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              person.age = person.age + 1
            end
          end
          return population
        end

  - name: "mortality"
    type: "lua_model"
    priority: 2
    enabled: true
    description: "Age-specific mortality: 0.1% for under 30, 5% for 30+"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              local age = person.age
              local prob = 0
              
              if age < 30 then
                prob = 0.001
              else
                prob = 0.05
              end
              
              if math.random() < prob then
                person.alive = false
              end
            end
          end
          return population
        end

statistics:
  - name: "population_status"
    description: "Alive and dead counts"
    script: |
      function statistic(population)
        local alive = 0
        local dead = 0
        for _, person in ipairs(population) do
          if person.alive == true then
            alive = alive + 1
          else
            dead = dead + 1
          end
        end
        return { alive = alive, dead = dead }
      end
  
  - name: "age_distribution"
    description: "Age groups - alive only"
    script: |
      function statistic(population)
        local children = 0
        local adults = 0
        local elderly = 0
        
        for _, person in ipairs(population) do
          if person.alive == true then
            local age = person.age
            if age < 18 then
              children = children + 1
            elseif age >= 18 and age < 65 then
              adults = adults + 1
            else
              elderly = elderly + 1
            end
          end
        end
        
        return {
          children = children,
          adults = adults,
          elderly = elderly
        }
      end
  
  - name: "sex_distribution"
    description: "Sex distribution - alive only"
    script: |
      function statistic(population)
        local females = 0
        local males = 0
        
        for _, person in ipairs(population) do
          if person.alive == true then
            if person.sex == "F" then
              females = females + 1
            else
              males = males + 1
            end
          end
        end
        
        return { females = females, males = males }
      end
  
  - name: "average_age"
    description: "Average age - alive only"
    script: |
      function statistic(population)
        local total_age = 0
        local count = 0
        
        for _, person in ipairs(population) do
          if person.alive == true then
            total_age = total_age + person.age
            count = count + 1
          end
        end
        
        local avg_age = 0
        if count > 0 then
          avg_age = total_age / count
        end
        
        return { avg_age = avg_age }
      end
  
  - name: "age_range"
    description: "Youngest and oldest ages - alive only"
    script: |
      function statistic(population)
        local youngest = nil
        local oldest = nil
        
        for _, person in ipairs(population) do
          if person.alive == true then
            if youngest == nil or person.age < youngest then
              youngest = person.age
            end
            if oldest == nil or person.age > oldest then
              oldest = person.age
            end
          end
        end
        
        return { youngest = youngest or 0, oldest = oldest or 0 }
      end
  
  - name: "dependency_ratio"
    description: "Dependency ratio (dependents per 100 working-age adults)"
    script: |
      function statistic(population)
        local dependents = 0
        local workers = 0
        
        for _, person in ipairs(population) do
          if person.alive == true then
            if person.age < 18 or person.age >= 65 then
              dependents = dependents + 1
            else
              workers = workers + 1
            end
          end
        end
        
        local ratio = 0
        if workers > 0 then
          ratio = (dependents / workers) * 100
        end
        
        return { dependency_ratio = ratio }
      end
```

---

## Summary

In this tutorial, you've learned:

1. **YAML Rules**: 
   - Use spaces, not tabs
   - Use the pipe (`|`) for multi-line strings
   - Column names must match your CSV exactly

2. **Lua in Plain English**:
   - Lua is just instructions that read like English
   - `function` = "Here's a model"
   - `for` = "For each person"
   - `if` = "If this is true"
   - `math.random()` = "Roll a dice"

3. **Mortality Model**:
   - Applied age-specific death probabilities
   - Used `math.random()` for probabilistic events
   - Understood priority ordering (age first, then mortality)

4. **Statistics**:
   - Age distribution (children, adults, elderly)
   - Sex distribution
   - Average age
   - Age range
   - Dependency ratio

## Next Steps

In the next tutorial, you'll learn how to:
- Add fertility (births) to your model
- Track population growth
- Work with household-level data
- Create complex models like household formation

---

**Well done for completing Tutorial 2!** You now understand YAML rules, can write Lua statistics, and have built a working aging and mortality model. You're ready for more complex models.