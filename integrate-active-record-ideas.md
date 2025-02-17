# problem

We can expose commands via rails router however we don't really expose
active record models in any real way

# possible solutions

* Create a brand-new Foobara type that knows all about ActiveRecord classes/objects.
  * Can it inherit detached entity? This would prevent transactional behavior but
    give discoverability.
  * Inherit entity?
    * Pretty challenging. This would require either:
      1. a custom CRUD driver unlike inheriting from DetachedEntity, or 
      2. extending ActiveRecord::Base to implement the Entity interface
        * kind of risky. Might have to hook into active record to detect
          changes to the record to fire off the needed entity callbacks.
          And without an existing RDBMS crud driver we don't really have prior
          art for transaction rollbacks.
      3. Making the entity record proxy to a hidden active record record.
        * Might put pressure to create large amounts of the active record interface.

# Decision for now?

* Attempt to extend DetachedEntity?
  * cast to/from and ActiveRecord object.
  * Extend ActiveRecord::Base with needed methods for type behavior? We need to 
    be able to go from an active record record or class to 
    foobara manifest metadata for example.
* Create new type from scratch?

# other thoughts

We would benefit from extracting entities/persistence from the foobara monorepo.

The reason is in the case where we don't utilize it at all for active record integration,
we can reduce the foobara memory footprint and improve performance potentially
if we exclude entities/persistence and its plumbing.

What does our type need?

ExtendActiveRecordHandler and/or an ExtendRegisteredActiveRecordHandler clases?
  Needs to have a target class of the active record class
Casters:
  cast from primary key?  Does active record have a thunk-like concept?  Do we need such a concept?
