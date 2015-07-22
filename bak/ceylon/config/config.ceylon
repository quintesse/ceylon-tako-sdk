import ceylon.collection { ... }

"Class for configuration values... blah blah"
by("Tako Schotanus")
shared class Config() {
    value options = HashMap<String, String[]>();
    value optionNames = HashMap<String, HashSet<String>>();
    value sectionNames = HashMap<String, HashSet<String>>();
    sectionNames.put("", HashSet<String>());
    
    class Key(String key) {
        shared String subsectionName; 
        shared String optionName;
        shared String sectionName;
        shared String parentSectionName;
        
        value parts = key.split(".").sequence;
        assert(parts.size >= 2);
        
        subsectionName = parts[parts.size - 2] else ""; 
        optionName = parts[parts.size - 1] else "";
        // TODO check if the following works as well
        // parentSectionName = ".".join(*parts[0..parts.size-2]);
        variable String parent = "";
        if (parts.size > 2) {
            for (Integer i in 0..parts.size-2) {
                if (i > 0) {
                    parent += ".";
                }
                parent += parts[i] else "";
            }
            sectionName = parent + "." + subsectionName;
        } else {
            sectionName = subsectionName;
        }
        parentSectionName = parent;
    }
    
    void initLookupKey(String key) {
        Key k = Key(key);

        if (!k.parentSectionName.empty) {
            initLookupKey(k.parentSectionName + ".#");
        }
        
        value psn = sectionNames.get(k.parentSectionName);
        assert(exists psn);
        psn.add(k.subsectionName);
        
        if (!sectionNames.get(k.sectionName) exists) {
            value sn = HashSet<String>();
            sectionNames.put(k.sectionName, sn);
        }
        
        if (!"#".equals(k.optionName)) {
            if (!optionNames.defines(k.sectionName)) {
                optionNames.put(k.sectionName, HashSet<String>());
            }
            value on = optionNames.get(k.sectionName);
            assert(exists on);
            on.add(k.optionName);
        }
    }
    
    shared Boolean defines(String key) => options.defines(key);
    
    shared void remove(String key) {
        options.remove(key);
        
        Key k = Key(key);
        value on = optionNames.get(k.sectionName);
        if (exists on) {
            on.remove(k.optionName);
        }
    }
    
    shared String[] getValues(String key) => options.get(key) else [];
    
    shared void setValues(String key, String[]? values) {
        if (exists values, values.size > 0) {
            options.put(key, values);
            initLookupKey(key);
        } else {
            remove(key);
        }
    }
    
    shared String? get(String key) => getValues(key).first;
    
    shared void set(String key, String newValue) => setValues(key, [ newValue ]);
    
    shared Boolean definesSection(String section) => sectionNames.defines(section);
    
    /**
     * Returns the list of all section names, the root section names
     * or the sub section names of the given section depending on the
     * argument being passed
     * @param section Returns the subsections of the section being passed.
     * Will return the root section names if being passed an empty string.
     * And will return all section names if being passed null.
     * @return An array of the requested section names
     */
    shared String[] getSectionNames(String? section = null) {
        HashSet<String> sn;
        if (exists section) {
            if (exists x = sectionNames.get(section)) {
                sn = x;
            } else {
                return [];
            }
        } else {
            sn = HashSet<String>();
            sn.addAll(*sectionNames.keys.sequence);
            sn.remove("");
        }
        return sn.sequence;
    }
    
    shared String[] getOptionNames(String? section = null) {
        if (exists section) {
            if (definesSection(section)) {
                value on = optionNames.get(section);
                if (exists on) {
                    return on.sequence;
                }
            }
            return [];
        } else {
            return options.keys.sequence;
        }
    }
    
    shared Config merge(Config local) {
        for (String key in local.getOptionNames(null)) {
            String[] values = local.getValues(key);
            setValues(key, values);
        }
        return this;
    }

    shared Config copy() => Config().merge(this);

    shared actual String string {
        //try {
        //    ByteArrayOutputStream out = new ByteArrayOutputStream();
        //    ConfigWriter.write(this, out);
        //    return out.toString("UTF-8");
        //} catch (IOException e) {
        //    return super.toString();
        //}
        // TODO temporary solution until we can get the above to work
        return options.fold(
            StringBuilder(),
            (StringBuilder partial, String->String[] elem)
                => partial.append(elem.key)
                        .append(" = ")
                        .append(elem.item.string)
                        .append("\n")).string;
    }
}