import ceylon.test { ... }
import ceylon.config { ... }

"Tests for the `ceylon.config` module."
void run() {
    suite("ceylon.config", 
        "Options" -> testOptions
    );    
}

void testOptions() {
    value cfg = Config();
    assertFalse(cfg.defines("foo.bar"));
    cfg.set("foo.bar", "true");
    assertTrue(cfg.defines("foo.bar"));
    assertEquals("true", cfg.get("foo.bar"));
}