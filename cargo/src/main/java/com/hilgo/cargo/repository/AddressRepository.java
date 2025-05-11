package com.hilgo.cargo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.hilgo.cargo.entity.Address;

@Repository
public interface AddressRepository extends JpaRepository<Address, Long>{

}
