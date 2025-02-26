package com.hilgo.Exercise_1.repo;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.hilgo.Exercise_1.Entity.Driver;

@Repository
public interface DriverRepository extends JpaRepository<Driver, Long>{

}
