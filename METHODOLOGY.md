# Universal Problem-Solving & Execution Methodology

## Core Principle: **Observe → Understand → Act → Verify**

Always follow this sequence: First observe reality, then understand it, then act deliberately, then verify the result.

---

## 🎯 Universal Workflow

### Phase 1: OBSERVE (What is the current state?)

**Before making ANY changes or assumptions:**
1. **Read actual state** - Don't assume, verify
   - Read configuration files
   - Check runtime state
   - Review logs/errors
   - Examine existing code

2. **Check fundamentals first** - Simple before complex
   - Network: routing, interfaces, connectivity
   - Services: status, processes, ports
   - Code: imports, dependencies, syntax
   - Config: files exist, syntax valid, conflicts?

3. **Look for obvious issues** - Don't miss the simple problems
   - Multiple conflicting configurations
   - Missing dependencies
   - Syntax errors
   - Obvious misconfigurations

### Phase 2: UNDERSTAND (What is the problem?)

1. **Define the gap**
   - Expected behavior: What should happen?
   - Actual behavior: What is happening?
   - Symptom: What is the observable issue?

2. **Identify likely causes**
   - Is it in fundamentals? (most likely)
   - Is it obvious? (check immediately)
   - Is it in advanced diagnostics? (less likely)

3. **Prioritize investigation**
   - Start with simplest explanations
   - Check fundamentals before advanced
   - Don't jump to complex solutions

### Phase 3: ACT (Make deliberate changes)

1. **One change at a time**
   - Make single, focused change
   - Test immediately
   - Verify result before next change

2. **Make changes persistent**
   - Update configuration files, not just runtime
   - Use proper tools and methods
   - Document what changed and why

3. **Follow proper procedures**
   - Use correct tools (sudo where needed)
   - Follow system conventions
   - Respect existing architecture

### Phase 4: VERIFY (Did it work?)

1. **Test the change**
   - Run the same test that showed the problem
   - Check if issue is resolved
   - Verify no new issues introduced

2. **Check completeness**
   - Is the fix complete?
   - Are all related issues resolved?
   - Is the change persistent?

3. **Document the solution**
   - What was the problem?
   - What was the fix?
   - Why did it work?

---

## 🔍 Universal Investigation Principles

### 1. **Read Before Write**
- Always read current state before modifying
- Understand what exists before changing it
- Check actual files, not assumptions

### 2. **Simple Before Complex**
- Check fundamentals first
- Look for obvious issues
- Don't overcomplicate

### 3. **Observe Before Diagnose**
- See what's actually happening
- Don't jump to conclusions
- Verify symptoms before fixing

### 4. **One Step at a Time**
- Make one change
- Test immediately
- Verify before proceeding

### 5. **Verify Everything**
- Test after each change
- Confirm expected behavior
- Check for side effects

---

## ⚠️ Universal Pitfalls to Avoid

### ❌ **Skipping Observation**
- Don't assume current state
- Don't skip reading configs/code
- Don't jump to solutions

### ❌ **Missing the Obvious**
- Don't ignore simple problems
- Don't miss obvious issues
- Don't overcomplicate simple fixes

### ❌ **Assuming Instead of Verifying**
- Don't assume configs are correct
- Don't assume code works as expected
- Don't assume services are configured properly

### ❌ **Multiple Changes at Once**
- Don't make several changes simultaneously
- Don't skip testing between changes
- Don't lose track of what changed

### ❌ **Runtime-Only Changes**
- Don't make temporary fixes without persistence
- Don't forget to update config files
- Don't leave changes undocumented

### ❌ **Not Verifying**
- Don't assume changes worked
- Don't skip testing
- Don't ignore verification step

---

## 📋 Universal Checklist Template

### For ANY Problem/Task:

**Before Starting:**
- [ ] Understand what the user wants
- [ ] Read current state (files, configs, code)
- [ ] Check fundamentals (status, routing, syntax, etc.)
- [ ] Look for obvious issues
- [ ] Identify expected vs actual behavior

**While Working:**
- [ ] Make one change at a time
- [ ] Test after each change
- [ ] Verify the change worked
- [ ] Make changes persistent
- [ ] Document what you're doing

**After Completion:**
- [ ] Verify the fix completely resolves the issue
- [ ] Check for side effects
- [ ] Ensure changes are persistent
- [ ] Document the solution

---

## 🔧 Domain-Specific Fundamentals

### Network Issues
**Check in order:**
1. Routing table (`ip route show`)
2. Interface status (`ip link show`)
3. IP configuration (`ip addr show`)
4. Basic connectivity (`ping`)
5. Configuration files
6. Logs (if still unresolved)

### Service Issues
**Check in order:**
1. Service status (`systemctl status`)
2. Process existence (`ps aux | grep`)
3. Listening ports (`ss -tuln`)
4. Configuration files
5. Logs (`journalctl`)

### Code Issues
**Check in order:**
1. Syntax errors (linting, compilation)
2. Import/dependency issues
3. Runtime errors (logs, stack traces)
4. Configuration/environment
5. Logic errors (debugging)

### Configuration Issues
**Check in order:**
1. File exists and readable
2. Syntax is valid
3. No conflicting configs
4. Applied correctly
5. Runtime state matches config

### Docker/Container Issues
**Check in order:**
1. Container status (`docker ps -a`)
2. Container logs (`docker logs`)
3. Configuration (`docker inspect`)
4. Port mappings
5. Data volumes
6. Docker daemon status

---

## 🎯 Execution Principles

### 1. **Read First, Write Second**
```
1. Read current state
2. Understand what exists
3. Plan the change
4. Make the change
5. Verify the change
```

### 2. **Simple First, Complex Later**
```
1. Check fundamentals
2. Look for obvious issues
3. Try simple fixes
4. Only then try complex solutions
```

### 3. **Change, Test, Verify, Repeat**
```
1. Make one change
2. Test immediately
3. Verify result
4. If good, proceed; if not, revert
```

### 4. **Persist, Don't Just Patch**
```
1. Make runtime change (if needed for testing)
2. Update configuration file
3. Verify persistence
4. Test after reboot/restart
```

### 5. **Document Reality, Not Assumptions**
```
1. Document what you actually see
2. Document what you actually change
3. Document what actually works
4. Don't document assumptions
```

---

## 🎓 Learning Framework

### After Each Task:
1. **What worked?** - What approach was effective?
2. **What didn't?** - What approach failed or was inefficient?
3. **What was missed?** - What obvious issue was overlooked?
4. **How to improve?** - What should be done differently next time?

### Pattern Recognition:
- If similar issues appear, apply same methodology
- Learn from mistakes in previous sessions
- Build mental checklist based on experience
- Recognize when to check fundamentals vs. advanced diagnostics

---

## 📝 Quick Reference Matrix

| Domain | Fundamental Checks | Before Making Changes |
|--------|-------------------|----------------------|
| **Network** | Routing, interfaces, connectivity | Read netplan/configs |
| **Services** | Status, process, ports | Read systemd/service configs |
| **Code** | Syntax, imports, dependencies | Read existing codebase |
| **Config** | Files exist, syntax valid | Read current configs |
| **Docker** | Container status, logs | Read docker-compose/inspect |

---

## 🎯 Success Criteria

A successful execution:
- ✅ **Observed** actual state before acting
- ✅ **Understood** the problem clearly
- ✅ **Acted** with deliberate, single changes
- ✅ **Verified** each change worked
- ✅ **Persisted** changes properly
- ✅ **Completed** without requiring user hints
- ✅ **Resolved** the issue completely

---

## 🔄 Continuous Improvement

### For Each Session:
1. Apply this methodology consistently
2. Note when you deviate (and why)
3. Learn from mistakes
4. Refine approach based on results

### For User:
- Can reference this methodology: "follow methodology"
- Can point out when I'm skipping steps
- Can request systematic approach for any task

---

**Last Updated:** November 4, 2025
**Purpose:** Universal methodology for effective and reliable problem-solving in all domains
**Status:** Living document - improve based on experience
