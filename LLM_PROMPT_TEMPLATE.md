# Talos LLM Prompt Template

Copy and paste this entire message into your LLM (ChatGPT, Claude, etc.) to get help with Talos models.

---

## Context: Talos Migration Microsimulation Engine

Talos is a self-contained demographic microsimulation engine. Models are defined in YAML configuration files with embedded Lua scripts.

**Core Concepts:**
- **Population**: CSV file with one row per person
- **Models**: Lua scripts that transform the population each year
- **Statistics**: Lua scripts that compute metrics about the population
- **YAML**: Configuration file that ties everything together

**Data Structure:**
- Population is a list of tables (each person is a table)
- Each person has key-value pairs from the CSV columns
- Example: `person.age`, `person.sex`, `person.alive`, `person.area`

**Lua Script Structure:**
```lua
-- Model: runs each year to transform the population
function transition(population, params)
  for _, person in ipairs(population) do
    -- Your logic here
  end
  return population
end

-- Statistic: computes metrics each year
function statistic(population)
  -- Your logic here
  return { result = value }
end
```

**Built-in Lua Functions:**
- `math.random()` - random number between 0 and 1
- `math.random(n)` - random integer between 1 and n
- `math.random(min, max)` - random integer between min and max
- `math.floor(x)` - round down
- `math.ceil(x)` - round up
- `math.round(x)` - round to nearest integer

**YAML Structure:**
```yaml
simulation:
  iterations: 10
  population_file: "population.csv"
  output_file: "output.csv"
  random_seed: 42
  verbose: true
  id_column: "person_id"

models:
  - name: "model_name"
    type: "lua_model"
    priority: 1
    enabled: true
    description: "What this model does"
    parameters:
      rate: 0.05
      script: |
        function transition(population, params)
          -- Your model logic here
          return population
        end

statistics:
  - name: "statistic_name"
    description: "What this statistic shows"
    script: |
      function statistic(population)
        -- Your statistic logic here
        return { result = value }
      end
```

---

## Example Models

### 1. Aging Model
```lua
function transition(population, params)
  for _, person in ipairs(population) do
    if person.alive == true then
      person.age = person.age + 1
    end
  end
  return population
end
```

### 2. Mortality Model
```lua
function transition(population, params)
  local rates = params.mortality_rates
  for _, person in ipairs(population) do
    if person.alive == true then
      local age = person.age
      local prob = 0
      if age < 1 then
        prob = rates.infant
      elseif age >= 85 then
        prob = rates.elderly
      end
      if math.random() < prob then
        person.alive = false
      end
    end
  end
  return population
end
```

### 3. Migration Model
```lua
function transition(population, params)
  local rates = params.migration_rates
  local num_areas = params.num_areas
  
  for _, person in ipairs(population) do
    if person.alive == true then
      local age = person.age
      local prob = 0
      
      if age < 18 then
        prob = rates.child_0_17
      elseif age >= 18 and age < 35 then
        prob = rates.adult_18_34
      elseif age >= 35 and age < 65 then
        prob = rates.adult_35_64
      else
        prob = rates.elderly_65_plus
      end
      
      if math.random() < prob then
        person.previous_area = person.area
        person.area = math.random(1, num_areas)
      end
    end
  end
  return population
end
```

### 4. Fertility Model
```lua
function transition(population, params)
  local fertility_rate = params.fertility_rate or 0.05
  local newborns = {}
  
  local max_id = 0
  for _, person in ipairs(population) do
    if person.person_id ~= nil and person.person_id > max_id then
      max_id = person.person_id
    end
  end
  
  for _, person in ipairs(population) do
    if person.alive == true and person.sex == "F" then
      local age = person.age
      if age >= 15 and age < 50 then
        if math.random() < fertility_rate then
          max_id = max_id + 1
          local baby = {
            person_id = max_id,
            age = 0,
            sex = math.random() < 0.5 and "F" or "M",
            area = person.area,
            alive = true,
            mother_id = person.person_id
          }
          table.insert(newborns, baby)
        end
      end
    end
  end
  
  for _, baby in ipairs(newborns) do
    table.insert(population, baby)
  end
  
  return population
end
```

### 5. Education Model
```lua
function transition(population, params)
  for _, person in ipairs(population) do
    if person.alive == true then
      if person.age >= 5 and person.age <= 18 then
        if person.education == nil or person.education == "none" then
          person.education = "primary"
        elseif person.education == "primary" and person.age >= 11 then
          person.education = "secondary"
        elseif person.education == "secondary" and person.age >= 16 then
          if math.random() < 0.3 then
            person.education = "tertiary"
          end
        end
      end
    end
  end
  return population
end
```

### 6. Income Model
```lua
function transition(population, params)
  local base = params.base_income or 20000
  local education_bonus = params.education_bonus or {tertiary=15000, secondary=5000}
  
  for _, person in ipairs(population) do
    if person.alive == true and person.age >= 18 then
      local bonus = 0
      if person.education == "tertiary" then
        bonus = education_bonus.tertiary
      elseif person.education == "secondary" then
        bonus = education_bonus.secondary
      end
      local age_factor = math.min(1, (person.age - 18) / 20)
      local sex_factor = person.sex == "M" and 1.0 or 0.8
      person.income = (base + bonus) * age_factor * sex_factor
    end
  end
  return population
end
```

### 7. Household Formation Model
```lua
function transition(population, params)
  -- Add household_id if not present
  for _, person in ipairs(population) do
    if person.household_id == nil then
      person.household_id = person.person_id
    end
  end
  
  -- Young adults form new households
  for _, person in ipairs(population) do
    if person.alive == true and person.age >= 18 and person.age <= 25 then
      if math.random() < 0.05 then
        person.household_id = person.person_id
      end
    end
  end
  
  -- Children live with mothers
  for _, person in ipairs(population) do
    if person.alive == true and person.age < 18 and person.mother_id ~= nil then
      for _, mother in ipairs(population) do
        if mother.person_id == person.mother_id and mother.alive == true then
          person.household_id = mother.household_id
          break
        end
      end
    end
  end
  
  return population
end
```

---

## Statistics Examples

### 1. Population Count
```lua
function statistic(population)
  return { total = #population }
end
```

### 2. Alive/Dead Count
```lua
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

### 3. Age Distribution
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

### 4. Sex Distribution
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

### 5. Average Age
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

### 6. Age Range
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
  
  return {
    youngest = youngest or 0,
    oldest = oldest or 0
  }
end
```

### 7. Births Per Year
```lua
function statistic(population)
  local births = 0
  for _, person in ipairs(population) do
    if person.age == 0 and person.alive == true then
      births = births + 1
    end
  end
  return { births_this_year = births }
end
```

### 8. Dependency Ratio
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

### 9. Migration Statistics
```lua
function statistic(population)
  local migrants = 0
  local total = 0
  
  for _, person in ipairs(population) do
    if person.alive == true then
      total = total + 1
      if person.previous_area ~= nil and person.previous_area ~= person.area then
        migrants = migrants + 1
      end
    end
  end
  
  local rate = 0
  if total > 0 then
    rate = (migrants / total) * 100
  end
  
  return {
    migrants = migrants,
    total = total,
    migration_rate_pct = rate
  }
end
```

### 10. Area Distribution
```lua
function statistic(population)
  local areas = {}
  for _, person in ipairs(population) do
    if person.alive == true then
      local area = tostring(person.area)
      if areas[area] == nil then
        areas[area] = { total = 0, alive = 0 }
      end
      areas[area].total = areas[area].total + 1
      if person.alive == true then
        areas[area].alive = areas[area].alive + 1
      end
    end
  end
  return areas
end
```

### 11. Household Statistics
```lua
function statistic(population)
  local households = {}
  
  for _, person in ipairs(population) do
    if person.alive == true and person.household_id ~= nil then
      local hid = tostring(person.household_id)
      if households[hid] == nil then
        households[hid] = { size = 0, adults = 0, children = 0 }
      end
      households[hid].size = households[hid].size + 1
      if person.age >= 18 then
        households[hid].adults = households[hid].adults + 1
      else
        households[hid].children = households[hid].children + 1
      end
    end
  end
  
  local total_households = 0
  local total_size = 0
  local avg_size = 0
  
  for _, h in pairs(households) do
    total_households = total_households + 1
    total_size = total_size + h.size
  end
  
  if total_households > 0 then
    avg_size = total_size / total_households
  end
  
  return {
    total_households = total_households,
    avg_household_size = avg_size
  }
end
```

---

## YAML Configuration Template

```yaml
# config.yaml
simulation:
  iterations: 10
  population_file: "population.csv"
  output_file: "output.csv"
  random_seed: 42
  verbose: true
  id_column: "person_id"

models:
  # --- MODEL 1: Aging ---
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

  # --- MODEL 2: [YOUR MODEL HERE] ---
  # Add more models here

statistics:
  # --- STATISTIC 1: Total Population ---
  - name: "population_total"
    description: "Total population"
    script: |
      function statistic(population)
        return { total = #population }
      end

  # --- STATISTIC 2: [YOUR STATISTIC HERE] ---
  # Add more statistics here
```

---

## How to Use This Template

1. **Copy the entire template above** into your LLM
2. **Describe what you want to build** with one of these prompts:
   - "I want to build a model that does [X]"
   - "My population has columns [A, B, C]"
   - "I want to track statistics [Y, Z]"
3. **The LLM will generate** the YAML and Lua code for you
4. **Test it** by running Talos with your new configuration
5. **Iterate** - ask follow-up questions to refine your model

## Example Questions to Ask the LLM

### Basic Models
1. "I want to add a model where people get married. Women marry at age 20-30, men at 22-35. How do I write this?"
2. "I need a fertility model where fertility rates vary by age: 15-19: 2%, 20-24: 8%, 25-29: 10%, 30-34: 8%, 35-39: 4%, 40-44: 1%"
3. "How do I create an education model where children progress through primary, secondary, and tertiary education?"

### Statistics
4. "How do I create a statistic that shows the median age of the population?"
5. "I want a statistic that shows the dependency ratio (children + elderly / working age)."
6. "How do I create a statistic that shows household size distribution?"

### Complex Models
7. "I want migration to depend on distance between areas. How do I implement this?"
8. "I need a household formation model where young adults leave their parents' household."
9. "How do I model income where it depends on age, education, and sex?"

### Advanced
10. "How do I add a new column to each person when they get married?"
11. "I want to track the number of children each woman has (parity)."
12. "How do I model international migration where people leave permanently?"

---

## Example: Full Conversation

**User:**
"I want to build a model where people can move between areas. The probability of moving depends on age. Young adults (18-34) are most mobile with 8% chance, children (0-17) have 2%, middle-aged (35-64) have 3%, and elderly (65+) have 1%. There are 5 areas."

**LLM Response:**

```lua
function transition(population, params)
  local rates = params.migration_rates
  local num_areas = params.num_areas
  
  for _, person in ipairs(population) do
    if person.alive == true then
      local age = person.age
      local prob = 0
      
      if age < 18 then
        prob = rates.child_0_17
      elseif age >= 18 and age < 35 then
        prob = rates.adult_18_34
      elseif age >= 35 and age < 65 then
        prob = rates.adult_35_64
      else
        prob = rates.elderly_65_plus
      end
      
      if math.random() < prob then
        person.previous_area = person.area
        person.area = math.random(1, num_areas)
      end
    end
  end
  return population
end
```

Then add this to your `config.yaml`:

```yaml
models:
  - name: "migration"
    type: "lua_model"
    priority: 3
    enabled: true
    description: "Age-based migration between areas"
    parameters:
      migration_rates:
        child_0_17: 0.02
        adult_18_34: 0.08
        adult_35_64: 0.03
        elderly_65_plus: 0.01
      num_areas: 5
      script: |
        function transition(population, params)
          local rates = params.migration_rates
          local num_areas = params.num_areas
          
          for _, person in ipairs(population) do
            if person.alive == true then
              local age = person.age
              local prob = 0
              
              if age < 18 then
                prob = rates.child_0_17
              elseif age >= 18 and age < 35 then
                prob = rates.adult_18_34
              elseif age >= 35 and age < 65 then
                prob = rates.adult_35_64
              else
                prob = rates.elderly_65_plus
              end
              
              if math.random() < prob then
                person.previous_area = person.area
                person.area = math.random(1, num_areas)
              end
            end
          end
          return population
        end
```

---
