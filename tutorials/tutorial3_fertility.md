# Talos Tutorial 3: Adding Fertility

## Overview

In this tutorial, you'll learn how to add fertility to your demographic model. We'll build on the aging and mortality model from Tutorial 2, adding births to create a more complete population simulation. You'll learn how to create new individuals, assign their characteristics, and track population growth.

## What You'll Learn

By the end of this tutorial, you'll be able to:
- Add a fertility model to your simulation
- Create new individuals (births) with appropriate characteristics
- Track population growth and fertility statistics
- Understand how to work with household-level data
- Write complex Lua models that modify the population

## Prerequisites

- Completion of Tutorial 2 (or equivalent knowledge)
- The `population.csv` file from Tutorial 1
- A text editor

---

## Part 1: What We're Going to Build

So far we have:
- ✅ **Aging**: Everyone gets older each year
- ✅ **Mortality**: Some people die based on their age

Now we'll add:
- **Fertility**: Women of childbearing age can give birth

### What We Want to Do

**In plain English:** "Each year, for every woman aged 15-49 who is alive, there is a 5% chance she gives birth. If she gives birth, we add a new person to the population. The new baby inherits the mother's area, is randomly male or female, and is marked as alive."

### Why This Matters

Adding fertility completes the demographic cycle:
- **Births** add people to the population
- **Aging** moves people through the life course
- **Deaths** remove people from the population

With all three models, we can simulate realistic population dynamics.

---

## Part 2: Understanding Lua Table Operations

Before we write our fertility model, let's understand how to work with tables (lists) in Lua.

### Adding Items to a Table

In Lua, `table.insert()` adds a new item to the end of a list:

```lua
-- Create a list
local newborns = {}

-- Add a new person to the list
table.insert(newborns, {
  person_id = 11,
  age = 0,
  sex = "F",
  area = 1,
  alive = true
})
```

### Creating a New Person

A person is just a table with properties:

```lua
local baby = {
  person_id = 11,
  age = 0,
  sex = "F",
  area = 1,
  alive = true
}
```

### Finding the Maximum ID

To create new unique IDs, we need to find the highest existing ID:

```lua
local max_id = 0
for _, person in ipairs(population) do
  if person.person_id > max_id then
    max_id = person.person_id
  end
end
```

Then the next ID is `max_id + 1`.

---

## Part 3: The Fertility Model in Lua

### The Complete Fertility Model

Here's the Lua script for our fertility model:

```lua
function transition(population, params)
  -- Get fertility rate from parameters
  local fertility_rate = params.fertility_rate or 0.05
  
  -- Create a list for newborns
  local newborns = {}
  
  -- Find the maximum ID
  local max_id = 0
  for _, person in ipairs(population) do
    if person.person_id ~= nil and person.person_id > max_id then
      max_id = person.person_id
    end
  end
  
  -- Process each person
  for _, person in ipairs(population) do
    -- Check if this person is a fertile woman
    if person.alive == true and person.sex == "F" then
      local age = person.age
      if age >= 15 and age < 50 then
        -- Roll the dice for fertility
        if math.random() < fertility_rate then
          -- Create a newborn
          max_id = max_id + 1
          local baby = {
            person_id = max_id,
            age = 0,
            sex = math.random() < 0.5 and "F" or "M",
            area = person.area,
            alive = true
          }
          table.insert(newborns, baby)
        end
      end
    end
  end
  
  -- Add newborns to population
  for _, baby in ipairs(newborns) do
    table.insert(population, baby)
  end
  
  return population
end
```

### Breaking It Down Piece by Piece

**First, in plain English:** "Go through every woman who is alive and aged 15-49. For each one, flip a coin. If it comes up heads (5% chance), create a new baby. The baby gets a new ID, age 0, a random sex (50:50), and lives in the same area as the mother. The baby is alive."

**Now let's break down each part:**

| Part | What it does | In plain English |
|------|--------------|------------------|
| `local fertility_rate = params.fertility_rate or 0.05` | Get rate | "Use the rate from the config, or 5% if not specified" |
| `local newborns = {}` | Create list | "Create an empty list for babies born this year" |
| `for _, person in ipairs(population) do` | Loop through people | "For each person in the population..." |
| `if person.alive == true and person.sex == "F" then` | Check woman | "...if they are a woman and alive..." |
| `if age >= 15 and age < 50 then` | Check age | "...and they're of childbearing age (15-49)..." |
| `if math.random() < fertility_rate then` | Roll dice | "...roll a random number..." |
| `max_id = max_id + 1` | New ID | "...if it's less than the fertility rate, create a new ID" |
| `local baby = { ... }` | Create baby | "...create a new baby with properties" |
| `table.insert(newborns, baby)` | Add to list | "...add the baby to the list of newborns" |
| `table.insert(population, baby)` | Add to population | "...add the baby to the population" |

### Understanding the New ID Generation

```lua
-- Find the maximum ID
local max_id = 0
for _, person in ipairs(population) do
  if person.person_id ~= nil and person.person_id > max_id then
    max_id = person.person_id
  end
end

-- Then later, when creating a baby:
max_id = max_id + 1
local baby = {
  person_id = max_id,
  ...
}
```

**Why do we need this?** We need unique IDs for each new person. If the highest ID is 10, the next should be 11, then 12, etc.

### Understanding Random Sex Assignment

```lua
sex = math.random() < 0.5 and "F" or "M"
```

**In plain English:** "Flip a coin. If it's heads (50% chance), the baby is female. Otherwise, the baby is male."

This is a Lua shorthand for:

```lua
if math.random() < 0.5 then
  sex = "F"
else
  sex = "M"
end
```

---

## Part 4: Adding Fertility Statistics

Now let's add statistics to track fertility:

### Births This Year

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

**In plain English:** "Count all the people who are age 0 and alive. These are this year's births."

### Fertility Rate (Births per 1000 Women)

```lua
function statistic(population)
  local births = 0
  local women = 0
  
  for _, person in ipairs(population) do
    if person.alive == true then
      if person.age == 0 then
        births = births + 1
      end
      if person.sex == "F" and person.age >= 15 and person.age < 50 then
        women = women + 1
      end
    end
  end
  
  local rate = 0
  if women > 0 then
    rate = (births / women) * 1000
  end
  
  return { birth_rate_per_1000 = rate }
end
```

**In plain English:** "Take the number of births this year, divide by the number of women of childbearing age, multiply by 1000. This gives births per 1000 women."

### Newborns by Sex

```lua
function statistic(population)
  local females = 0
  local males = 0
  
  for _, person in ipairs(population) do
    if person.age == 0 and person.alive == true then
      if person.sex == "F" then
        females = females + 1
      else
        males = males + 1
      end
    end
  end
  
  return {
    female_newborns = females,
    male_newborns = males
  }
end
```

**In plain English:** "Count the number of female newborns and male newborns born this year."

---

## Part 5: Adding Fertility to Our Configuration

Here's our complete configuration with aging, mortality, and fertility:

```yaml
# config_aging_mortality_fertility.yaml
# Complete demographic model with aging, mortality, and fertility

simulation:
  iterations: 10
  population_file: "population.csv"
  output_file: "population_complete.csv"
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

  # Model 3: Fertility (runs third)
  - name: "fertility"
    type: "lua_model"
    priority: 3
    enabled: true
    description: "Fertility: 5% chance for women aged 15-49 to give birth"
    parameters:
      fertility_rate: 0.05
      script: |
        function transition(population, params)
          local fertility_rate = params.fertility_rate
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
                    alive = true
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
  
  - name: "fertility_stats"
    description: "Births in current year"
    script: |
      function statistic(population)
        local births = 0
        for _, person in ipairs(population) do
          if person.age == 0 and person.alive == true then
            births = births + 1
          end
        end
        return { births_this_year = births }
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
```

---

## Part 6: Running the Complete Model

Save the configuration as `config_aging_mortality_fertility.yaml` and run it:

```bash
./talos config_aging_mortality_fertility.yaml
```

### Expected Output

```
2024/01/15 10:00:00 ═══ Talos-Pure: Migration Microsimulation ═══
2024/01/15 10:00:00 Iterations: 10
2024/01/15 10:00:00 Population file: population.csv
2024/01/15 10:00:00 ID column: person_id
2024/01/15 10:00:00 Models loaded: 3
2024/01/15 10:00:00 Statistics defined: 5
2024/01/15 10:00:00 Loaded 10 individuals with 4 columns
2024/01/15 10:00:00 Columns: [person_id age sex area alive]
2024/01/15 10:00:00 Enabled models: 3
2024/01/15 10:00:00   - age_increment (priority: 1)
2024/01/15 10:00:00   - mortality (priority: 2)
2024/01/15 10:00:00   - fertility (priority: 3)

2024/01/15 10:00:00 ═══ Iteration 1/10 ═══
2024/01/15 10:00:00   ▶ age_increment
2024/01/15 10:00:00   ▶ mortality
2024/01/15 10:00:00   ▶ fertility
2024/01/15 10:00:00   📊 Statistics:
2024/01/15 10:00:00     population_status (Alive and dead counts): alive: 9, dead: 1
2024/01/15 10:00:00     age_distribution (Age groups): children: 2, adults: 5, elderly: 2
2024/01/15 10:00:00     fertility_stats (Births in current year): births_this_year: 0
2024/01/15 10:00:00     sex_distribution (Sex distribution): females: 4, males: 5
2024/01/15 10:00:00     average_age (Average age): avg_age: 42.8

...

2024/01/15 10:00:00 ═══ Iteration 5/10 ═══
2024/01/15 10:00:00   📊 Statistics:
2024/01/15 10:00:00     population_status (Alive and dead counts): alive: 8, dead: 2
2024/01/15 10:00:00     age_distribution (Age groups): children: 2, adults: 4, elderly: 2
2024/01/15 10:00:00     fertility_stats (Births in current year): births_this_year: 1
2024/01/15 10:00:00     sex_distribution (Sex distribution): females: 4, males: 4
2024/01/15 10:00:00     average_age (Average age): avg_age: 43.2

...

2024/01/15 10:00:00 ═══ Iteration 10/10 ═══
2024/01/15 10:00:00   📊 Statistics:
2024/01/15 10:00:00     population_status (Alive and dead counts): alive: 7, dead: 4
2024/01/15 10:00:00     age_distribution (Age groups): children: 2, adults: 3, elderly: 2
2024/01/15 10:00:00     fertility_stats (Births in current year): births_this_year: 2
2024/01/15 10:00:00     sex_distribution (Sex distribution): females: 3, males: 4
2024/01/15 10:00:00     average_age (Average age): avg_age: 44.1

2024/01/15 10:00:00 ═══ Simulation Complete ═══
2024/01/15 10:00:00 Results saved to population_complete.csv
```

### Understanding the Results

**Population Dynamics:**
- **Iteration 1**: 9 alive (1 death, no births yet)
- **Iteration 5**: 8 alive (1 birth, some deaths)
- **Iteration 10**: 7 alive (2 births in final year, cumulative deaths)

**What's happening?**
1. People age each year
2. Some older people die (5% chance for 30+)
3. Some women give birth (5% chance for 15-49)
4. The population changes in size and structure

---

## Part 7: Why Model Order Matters

The order of models is crucial. Here's why we run them in this specific order:

### Priority 1: Aging First

```yaml
priority: 1  # Runs first
```

**Why?** Women need to be the correct age for fertility. A woman who is 14 should not give birth, but if she turns 15 this year, she should be eligible.

### Priority 2: Mortality Second

```yaml
priority: 2  # Runs second
```

**Why?** Dead women shouldn't give birth. We need to remove people who die before checking fertility.

### Priority 3: Fertility Last

```yaml
priority: 3  # Runs last
```

**Why?** Newborns shouldn't be aged or killed in the same year they're born.

### Visualizing the Order

```
Start of Year
    ↓
1. AGE everyone (including women who turn 15)
    ↓
2. MORTALITY (dead people don't give birth)
    ↓
3. FERTILITY (women give birth to babies who are age 0)
    ↓
End of Year
```

---

## Part 8: Examining the Output CSV

After running the simulation, open `population_complete.csv`:

```csv
person_id,age,sex,area,alive
1,35,F,1,true
2,40,M,1,true
3,55,F,1,true
4,78,M,1,true
5,92,F,1,true
6,12,M,1,true
7,25,F,1,true
8,45,M,1,true
9,65,F,1,true
10,80,M,1,false
11,5,M,1,true
12,3,F,1,true
13,0,F,1,true
14,0,M,1,true
```

**Notice:**
- Person 10 is now dead (`alive = false`)
- Person 11-14 are new (they weren't in the original population)
- Persons 13 and 14 are age 0 (newborns from the final year)

---

## Part 9: Advanced Fertility - Age-Specific Rates

### The Problem

In our current model, all women 15-49 have the same 5% chance of giving birth. But in reality, fertility varies by age.

### What We Want to Do

**In plain English:** "Women in their 20s have the highest fertility, women in their 40s have much lower fertility."

### The Updated Lua Script

```lua
function transition(population, params)
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
      local rate = 0
      
      -- Age-specific fertility rates
      if age >= 15 and age < 20 then
        rate = 0.02   -- 2% chance
      elseif age >= 20 and age < 25 then
        rate = 0.08   -- 8% chance
      elseif age >= 25 and age < 30 then
        rate = 0.10   -- 10% chance (peak fertility)
      elseif age >= 30 and age < 35 then
        rate = 0.08   -- 8% chance
      elseif age >= 35 and age < 40 then
        rate = 0.04   -- 4% chance
      elseif age >= 40 and age < 45 then
        rate = 0.01   -- 1% chance
      elseif age >= 45 and age < 50 then
        rate = 0.001  -- 0.1% chance
      end
      
      if math.random() < rate then
        max_id = max_id + 1
        local baby = {
          person_id = max_id,
          age = 0,
          sex = math.random() < 0.5 and "F" or "M",
          area = person.area,
          alive = true
        }
        table.insert(newborns, baby)
      end
    end
  end
  
  for _, baby in ipairs(newborns) do
    table.insert(population, baby)
  end
  
  return population
end
```

### Understanding the Rates

| Age Group | Rate | Why |
|-----------|------|-----|
| 15-19 | 2% | Low - teenage pregnancies |
| 20-24 | 8% | Higher - peak childbearing years start |
| 25-29 | 10% | Peak fertility |
| 30-34 | 8% | Still high but declining |
| 35-39 | 4% | Declining |
| 40-44 | 1% | Low |
| 45-49 | 0.1% | Very low |

---

## Part 10: Advanced Fertility - Copying Mother's Characteristics

### The Problem

In our current model, babies only inherit the mother's area. But in reality, babies inherit many characteristics from their parents.

### What We Want to Do

**In plain English:** "When a baby is born, copy the mother's ethnicity, education, and other characteristics to the baby."

### The Updated Lua Script

First, let's add some columns to our CSV:

```csv
person_id,age,sex,area,alive,ethnicity,education,income
1,25,F,1,true,White,tertiary,45000
2,30,M,1,true,White,secondary,35000
3,45,F,1,true,Asian,tertiary,52000
...
```

Now, update the fertility script to copy these characteristics:

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
            -- Copy mother's characteristics
            ethnicity = person.ethnicity,
            education = "none",  -- Babies have no education yet
            income = 0           -- Babies have no income
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

### What's Changed

We added:
- `ethnicity = person.ethnicity` - Copy mother's ethnicity
- `education = "none"` - Set a default for babies
- `income = 0` - Set a default for babies

Now babies inherit their mother's ethnicity!

---

## Part 11: Advanced Fertility - Tracking Mother-Child Relationships

### The Problem

We want to track which mother had which child.

### What We Want to Do

**In plain English:** "When a baby is born, record the mother's ID. This allows us to track family relationships."

### The Updated Lua Script

```lua
function transition(population, params)
  local fertility_rate = params.fertility_rate or 0.05
  local newborns = {}
  local mothers_to_update = {}
  
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
            mother_id = person.person_id,  -- Track the mother
            parity = 0                     -- First child
          }
          table.insert(newborns, baby)
          
          -- Track that this mother needs parity update
          mothers_to_update[person.person_id] = true
        end
      end
    end
  end
  
  -- Add newborns to population
  for _, baby in ipairs(newborns) do
    table.insert(population, baby)
  end
  
  -- Update mother parity (number of children)
  for mother_id in pairs(mothers_to_update) do
    for _, person in ipairs(population) do
      if person.person_id == mother_id then
        person.parity = (person.parity or 0) + 1
        break
      end
    end
  end
  
  return population
end
```

### What's Changed

We added:
1. **`mother_id = person.person_id`** - Track which mother had the baby
2. **`parity = 0`** - Each baby starts with parity 0 (their own children count)
3. **`mothers_to_update`** - Track which mothers need their parity updated
4. **Second pass** - Update each mother's parity

### Understanding Parity

**Parity** is the number of children a woman has had.

- A woman who has had 2 children has parity 2
- A woman who has had 0 children has parity 0

When a woman gives birth, her parity increases by 1.

---

## Part 12: Complete Configuration with Advanced Fertility

Here's the full configuration with advanced fertility features:

```yaml
# config_advanced_fertility.yaml
# Complete model with advanced fertility

simulation:
  iterations: 10
  population_file: "population_advanced.csv"
  output_file: "population_advanced_output.csv"
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
    description: "Age-specific mortality"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              local age = person.age
              local prob = 0
              
              -- Age-specific mortality rates
              if age < 1 then
                prob = 0.005   -- Infant mortality
              elseif age >= 1 and age < 5 then
                prob = 0.0005
              elseif age >= 18 and age < 65 then
                prob = 0.001
              elseif age >= 65 and age < 85 then
                prob = 0.10
              else
                prob = 0.20
              end
              
              if math.random() < prob then
                person.alive = false
              end
            end
          end
          return population
        end

  # Model 3: Advanced Fertility
  - name: "fertility"
    type: "lua_model"
    priority: 3
    enabled: true
    description: "Age-specific fertility with parity tracking"
    parameters:
      script: |
        function transition(population, params)
          local newborns = {}
          local mothers_to_update = {}
          
          local max_id = 0
          for _, person in ipairs(population) do
            if person.person_id ~= nil and person.person_id > max_id then
              max_id = person.person_id
            end
          end
          
          for _, person in ipairs(population) do
            if person.alive == true and person.sex == "F" then
              local age = person.age
              local rate = 0
              
              -- Age-specific fertility rates
              if age >= 15 and age < 20 then
                rate = 0.02
              elseif age >= 20 and age < 25 then
                rate = 0.08
              elseif age >= 25 and age < 30 then
                rate = 0.10
              elseif age >= 30 and age < 35 then
                rate = 0.08
              elseif age >= 35 and age < 40 then
                rate = 0.04
              elseif age >= 40 and age < 45 then
                rate = 0.01
              elseif age >= 45 and age < 50 then
                rate = 0.001
              end
              
              if math.random() < rate then
                max_id = max_id + 1
                local baby = {
                  person_id = max_id,
                  age = 0,
                  sex = math.random() < 0.5 and "F" or "M",
                  area = person.area,
                  alive = true,
                  mother_id = person.person_id,
                  parity = 0,
                  ethnicity = person.ethnicity or "Unknown",
                  education = "none",
                  income = 0
                }
                table.insert(newborns, baby)
                mothers_to_update[person.person_id] = true
              end
            end
          end
          
          -- Add newborns
          for _, baby in ipairs(newborns) do
            table.insert(population, baby)
          end
          
          -- Update mother parity
          for mother_id in pairs(mothers_to_update) do
            for _, person in ipairs(population) do
              if person.person_id == mother_id then
                person.parity = (person.parity or 0) + 1
                break
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
  
  - name: "fertility_stats"
    description: "Births this year"
    script: |
      function statistic(population)
        local births = 0
        for _, person in ipairs(population) do
          if person.age == 0 and person.alive == true then            births = births + 1
          end
        end
        return { births_this_year = births }
      end
  
  - name: "average_parity"
    description: "Average children per woman (aged 15+)"
    script: |
      function statistic(population)
        local total_children = 0
        local women = 0
        
        for _, person in ipairs(population) do
          if person.alive == true and person.sex == "F" and person.age >= 15 then
            women = women + 1
            total_children = total_children + (person.parity or 0)
          end
        end
        
        local avg = 0
        if women > 0 then
          avg = total_children / women
        end
        
        return { avg_parity = avg }
      end
  
  - name: "newborns_by_sex"
    description: "Newborns by sex"
    script: |
      function statistic(population)
        local females = 0
        local males = 0
        
        for _, person in ipairs(population) do
          if person.age == 0 and person.alive == true then
            if person.sex == "F" then
              females = females + 1
            else
              males = males + 1
            end
          end
        end
        
        return {
          female_newborns = females,
          male_newborns = males
        }
      end
```

---

## Part 13: What You've Accomplished

Congratulations! You now have a complete demographic microsimulation model with:

1. ✅ **Aging**: Everyone gets older each year
2. ✅ **Mortality**: Age-specific death probabilities
3. ✅ **Fertility**: Women of childbearing age can give birth
4. ✅ **Age-Specific Fertility**: Different rates for different age groups
5. ✅ **Mother-Child Links**: Track which mother had which child
6. ✅ **Parity Tracking**: Track how many children each woman has
7. ✅ **Population Growth**: Births and deaths change population size
8. ✅ **Comprehensive Statistics**: Track population dynamics

### The Full Demographic Cycle

```
    ┌─────────────────────────────────────┐
    │                                     │
    │          POPULATION                 │
    │                                     │
    └─────────────┬───────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │                                     │
    │   1. AGE (everyone gets older)      │
    │                                     │
    └─────────────┬───────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │                                     │
    │   2. MORTALITY (some people die)    │
    │                                     │
    └─────────────┬───────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │                                     │
    │   3. FERTILITY (some women give birth)
    │                                     │
    └─────────────┬───────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │                                     │
    │   Next year: repeat!                │
    │                                     │
    └─────────────────────────────────────┘
```

---

## Part 14: What You Can Do Next

### 1. Add Education Models

```lua
function transition(population, params)
  for _, person in ipairs(population) do
    if person.alive == true and person.age >= 5 and person.age <= 18 then
      -- Progress through education
      if person.education == "none" then
        person.education = "primary"
      elseif person.education == "primary" and person.age >= 11 then
        person.education = "secondary"
      elseif person.education == "secondary" and person.age >= 16 then
        -- Could go to tertiary or leave
      end
    end
  end
  return population
end
```

### 2. Add Income Models

```lua
function transition(population, params)
  for _, person in ipairs(population) do
    if person.alive == true and person.age >= 18 then
      -- Income depends on age, education, and sex
      local base = 20000
      local education_bonus = 0
      if person.education == "tertiary" then
        education_bonus = 15000
      elseif person.education == "secondary" then
        education_bonus = 5000
      end
      local age_factor = math.min(1, (person.age - 18) / 20)  -- Peaks around 38
      local sex_factor = 0.8
      if person.sex == "M" then
        sex_factor = 1.0
      end
      person.income = (base + education_bonus) * age_factor * sex_factor
    end
  end
  return population
end
```

### 3. Add Household Formation

```lua
function transition(population, params)
  -- Add household_id column
  for _, person in ipairs(population) do
    if person.household_id == nil then
      person.household_id = person.person_id  -- Each person starts as their own household
    end
  end
  
  -- Young adults form households
  for _, person in ipairs(population) do
    if person.alive == true and person.age >= 18 and person.age <= 25 then
      if math.random() < 0.05 then  -- 5% chance per year
        person.household_id = person.person_id  -- New household
      end
    end
  end
  
  -- Children live with mothers
  for _, person in ipairs(population) do
    if person.alive == true and person.age < 18 and person.mother_id ~= nil then
      -- Find mother
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

### 4. Add Migration

```lua
function transition(population, params)
  local migration_rate = params.migration_rate or 0.05
  local num_areas = params.num_areas or 5
  
  for _, person in ipairs(population) do
    if person.alive == true then
      -- Migration probability by age
      local age = person.age
      local rate = 0
      if age < 18 then
        rate = migration_rate * 0.4
      elseif age >= 18 and age < 35 then
        rate = migration_rate * 1.5
      elseif age >= 35 and age < 65 then
        rate = migration_rate * 0.6
      else
        rate = migration_rate * 0.2
      end
      
      if math.random() < rate then
        person.previous_area = person.area
        person.area = math.random(1, num_areas)
      end
    end
  end
  
  return population
end
```

---

## Summary of Lua Concepts Learned

| Concept | What it does | Example |
|---------|--------------|---------|
| `table.insert()` | Add to list | `table.insert(list, item)` |
| `#` | Count items | `#population` |
| `math.random()` | Random number | `math.random()` or `math.random(1, 10)` |
| `..` | Concatenate strings | `"Hello " .. "World"` |
| `and` / `or` | Logical operators | `if person.alive and person.sex == "F"` |
| `{}` | Create table | `{ name = "John", age = 25 }` |
| `for` loop | Iterate | `for _, person in ipairs(population) do` |
| `if-elseif-else` | Conditions | `if age < 18 then ... end` |

---

**Well done for completing Tutorial 3!** You now have a complete demographic simulation with aging, mortality, and fertility. You understand the full demographic cycle and can build on this foundation for more complex models. You're ready to build your own microsimulation models!
